defmodule Zapnotes.Whatsapp do
  alias Zapnotes.Whatsapp.Webhook
  alias Zapnotes.Whatsapp.Worker.MessageProcessor

  def validate_verify_token(token) do
    if token == config(:verify_token) do
      :ok
    else
      {:error, :invalid_token}
    end
  end

  def validate_webhook_payload(raw_payload, sent_signature) do
    expected_signature =
      :crypto.mac(:hmac, :sha256, config(:secret_key), raw_payload)
      |> Base.encode16(case: :lower)

    if sent_signature == "sha256=#{expected_signature}" do
      :ok
    else
      {:error, :invalid_webhook_signature}
    end
  end

  def handle_webhook_payload(%{"entry" => entries}) do
    entries
    |> Webhook.entries_from_map()
    |> Webhook.messages_from_entries()
    |> Enum.map(fn message ->
      MessageProcessor.new(%{"message" => message})
    end)
    |> Oban.insert_all()

    Oban.resume_queue(queue: :whatsapp_message_process)

    :ok
  end

  defp config(key) do
    :zapnotes
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
