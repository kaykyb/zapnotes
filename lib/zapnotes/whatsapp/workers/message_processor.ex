defmodule Zapnotes.Whatsapp.Worker.MessageProcessor do
  alias Zapnotes.Accounts.User
  alias Zapnotes.Accounts
  use Oban.Worker, queue: :whatsapp_message_process, max_attempts: 3

  alias Zapnotes.Chats
  alias Zapnotes.Whatsapp
  alias Zapnotes.Whatsapp.Webhook
  alias Zapnotes.Chats.Workers.MessageIngestion

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    parsed_message = Webhook.Message.from_map(message)

    with {:ok, user} <- fetch_or_create_user(parsed_message.from),
         {:ok, chat_message} <- to_chat_messsage(parsed_message, user),
         {:ok, msg_id} <- Chats.push_message(chat_message) do
      msg_date = DateTime.from_unix!(parsed_message.timestamp)
      now = DateTime.utc_now()

      age = DateTime.diff(now, msg_date, :second)

      if age < 300 do
        MessageIngestion.dispatch(msg_id)
      end

      :ok
    end
  end

  def dispatch(message) do
    %{"message" => message}
    |> new()
    |> Oban.insert()

    Oban.resume_queue(queue: :whatsapp_message_process)
  end

  defp to_chat_messsage(%Webhook.Message{type: "text"} = msg, user) do
    msg = %Chats.Message{
      platform: :whatsapp,
      platform_id: msg.id,
      text: msg.text.body,
      user_id: user.id
    }

    {:ok, msg}
  end

  defp to_chat_messsage(%Webhook.Message{type: "audio"} = msg, user) do
    with {:ok, media} <- Whatsapp.Api.fetch_media(msg.audio.id) do
      msg = %Chats.Message{
        platform: :whatsapp,
        platform_id: msg.id,
        audio_url: media["url"],
        user_id: user.id
      }

      {:ok, msg}
    end
  end

  defp fetch_or_create_user(platform_uid) do
    Accounts.get_user_for_platform_uid(:whatsapp, platform_uid)
    |> case do
      nil ->
        %User{
          platform: :whatsapp,
          platform_uid: platform_uid
        }
        |> Accounts.create_user()

      user ->
        {:ok, user}
    end
  end
end
