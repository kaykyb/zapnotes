defmodule Zapnotes.Chats.ChatManagerSupervisor do
  use DynamicSupervisor

  alias Zapnotes.Chats.ChatManager

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def maybe_start_conversation(id) do
    case ChatManager.whereis(id) do
      nil -> start_conversation(id)
      pid -> {:ok, pid}
    end
  end

  defp start_conversation(id) do
    DynamicSupervisor.start_child(__MODULE__, {ChatManager, id})
  end
end
