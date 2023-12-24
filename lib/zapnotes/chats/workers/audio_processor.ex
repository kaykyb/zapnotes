defmodule Zapnotes.Chats.Workers.AudioProcessor do
  use Oban.Worker, queue: :audio_processing, max_attempts: 1

  alias Zapnotes.Chats
  alias Zapnotes.Chats.ChatHandler
  alias Zapnotes.Chats.ChatManager
  alias Zapnotes.Openai
  alias Zapnotes.Notion

  def perform(%Oban.Job{args: %{"chat_message_id" => chat_message_id}}) do
    message = Chats.get_message_by_id!(chat_message_id)

    # TODO: This should be a bucket instead of downloading from the platform
    with {:ok, audio_buffer} <- ChatHandler.fetch_audio(message.audio_url, message.platform),
         {:ok, transcription} <- Openai.Api.transcribe_with_whisper(audio_buffer),
         {:ok, summary} <- Openai.summarize_transcription(transcription),
         {:ok, blocks} <- structure_markdown(summary, transcription),
         {:ok, page_url} <-
           Notion.save_to_notion_audio_database(
             summary["title"],
             DateTime.utc_now(),
             message.user.platform_uid,
             blocks
           ) do
      ChatManager.handle_message_processing_complete(message.user_id, message, page_url)
      {:ok, page_url}
    end
  end

  def dispatch(chat_message_id) do
    new(%{"chat_message_id" => chat_message_id})
    |> Oban.insert()

    Oban.resume_queue(queue: :audio_processing)
  end

  defp structure_markdown(%{"summary" => summary, "content" => content}, transcript) do
    md = """
    # Summary

    #{summary}

    #{content}

    # Transcript

    #{transcript}
    """

    Notion.markdown_to_notion(md)
  end
end
