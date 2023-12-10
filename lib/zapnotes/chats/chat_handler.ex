defmodule Zapnotes.Chats.ChatHandler do
  alias Zapnotes.Whatsapp

  def fetch_audio(audio_url, :whatsapp), do: Whatsapp.ChatHandler.fetch_audio(audio_url)

  def audio_processing_complete(uid, :whatsapp),
    do: Whatsapp.ChatHandler.audio_processing_complete(uid)

  def already_processing(uid, :whatsapp), do: Whatsapp.ChatHandler.already_processing(uid)
  def processing_start(uid, :whatsapp), do: Whatsapp.ChatHandler.processing_start(uid)
  def start_idle(uid, :whatsapp), do: Whatsapp.ChatHandler.start_idle(uid)
end
