defmodule Zapnotes.Chats.Workers.MessageIngestion do
  use Oban.Worker, queue: :message_ingest, max_attempts: 3

  alias Zapnotes.Chats
  alias Zapnotes.Chats.ChatManager
  alias Zapnotes.Chats.ChatManagerSupervisor

  def perform(%Oban.Job{args: %{"chat_message_id" => chat_message_id}}) do
    message = Chats.get_message_by_id!(chat_message_id)

    ChatManagerSupervisor.maybe_start_conversation(message.user_id)

    with :ok <- ChatManager.ingest_message(message.user_id, message) do
      :ok
    end
  end

  def dispatch(chat_message_id) do
    new(%{"chat_message_id" => chat_message_id})
    |> Oban.insert()

    Oban.resume_queue(queue: :message_ingest)
  end
end
