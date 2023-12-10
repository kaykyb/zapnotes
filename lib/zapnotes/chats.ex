defmodule Zapnotes.Chats do
  alias Zapnotes.Repo
  alias Zapnotes.Chats.Message

  def push_message(%Message{} = msg) do
    with {:ok, msg} <- Repo.insert(msg) do
      {:ok, msg.id}
    end
  end

  @spec get_message_by_id!(String) :: Chats.Message
  def get_message_by_id!(id) do
    Repo.get!(Zapnotes.Chats.Message, id)
    |> Repo.preload([:user])
  end
end
