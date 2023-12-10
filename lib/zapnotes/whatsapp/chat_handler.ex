defmodule Zapnotes.Whatsapp.ChatHandler do
  alias Zapnotes.Whatsapp.Api

  def fetch_audio(audio_url) do
    with {:ok, file} <- Api.download_whatsapp_media(audio_url) do
      {:ok, file}
    end
  end

  def audio_processing_complete(uid) do
    Api.send_template_message(uid, "audio_processing_complete")
  end

  def already_processing(uid) do
    Api.send_template_message(uid, "already_processing")
  end

  def processing_start(uid) do
    Api.send_template_message(uid, "processing_start")
  end

  def start_idle(uid) do
    Api.send_template_message(uid, "start_idle")
  end
end
