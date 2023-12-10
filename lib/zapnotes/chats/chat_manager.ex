defmodule Zapnotes.Chats.ChatManager do
  use GenServer

  alias Zapnotes.Accounts
  alias Zapnotes.Chats.ChatHandler
  alias Zapnotes.Chats.Workers.AudioProcessor
  alias Zapnotes.Chats.Message

  defmodule State do
    @type conversation_step :: :idle | :processing_audio

    @enforce_keys [:message_queue, :step, :user_id]
    defstruct [:message_queue, :step, :user_id, :debouncer_pid]

    @type t :: %__MODULE__{
            user_id: String.t(),
            step: conversation_step,
            message_queue: list(Message),
            debouncer_pid: pid()
          }
  end

  def via_tuple(user_id) do
    Zapnotes.ProcessRegistry.via_tuple({__MODULE__, user_id})
  end

  def whereis(user_id) do
    case Zapnotes.ProcessRegistry.whereis_name({__MODULE__, user_id}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end

  @impl GenServer
  def init(user_id) do
    state = %State{
      message_queue: [],
      step: :idle,
      user_id: user_id
    }

    {:ok, state}
  end

  def ingest_message(user_id, %Message{} = message) do
    GenServer.call(via_tuple(user_id), {:ingest_message, message})
  end

  def handle_message_processing_complete(user_id, %Message{} = message, notion_url) do
    GenServer.call(
      via_tuple(user_id),
      {:handle_message_processing_complete, message, notion_url}
    )
  end

  @impl GenServer
  def handle_call({:ingest_message, %Message{} = message}, _from, %State{} = state) do
    # TODO: If the message is too old, do not ingest it, as the chat may have changed
    new_messages = [message] ++ state.message_queue
    {:ok, new_state} = %State{state | message_queue: new_messages} |> debounce()

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call(
        {:handle_message_processing_complete, %Message{}, _notion_url},
        _from,
        state
      ) do
    user = Accounts.get_user!(state.user_id)
    ChatHandler.audio_processing_complete(user.platform_uid, user.platform)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:process_messages, %State{} = state) do
    user = Accounts.get_user!(state.user_id)

    # For now, we only process one message at a time
    # TODO: Reverse the order to oldest first, latest last
    state.message_queue
    |> Enum.take(1)
    |> process_batch(state.step)
    |> case do
      {:error, :already_processing} ->
        ChatHandler.already_processing(user.platform_uid, user.platform)
        {:noreply, state}

      {:ok, :processing_audio} ->
        ChatHandler.processing_start(user.platform_uid, user.platform)
        {:noreply, %State{state | step: :processing_audio}}

      {:ok, :idle} ->
        res = ChatHandler.start_idle(user.platform_uid, user.platform)
        {:noreply, %State{state | step: :idle}}

      {:ok, :skip} ->
        {:noreply, state}
    end

    new_state = %State{state | message_queue: []}

    {:noreply, new_state}
  end

  defp debounce(%State{} = state) do
    if state.debouncer_pid do
      :timer.cancel(state.debouncer_pid)
    end

    {:ok, debouncer_pid} = :timer.send_after(:timer.seconds(1), :process_messages)

    {:ok, %State{state | debouncer_pid: debouncer_pid}}
  end

  defp process_batch(_, :processing_audio) do
    {:error, :already_processing}
  end

  defp process_batch([current_message], conversation_step),
    do: process_message(current_message, conversation_step)

  defp process_message(%Message{id: id, audio_url: audio_url}, :idle)
       when not is_nil(audio_url) do
    AudioProcessor.dispatch(id)
    {:ok, :processing_audio}
  end

  defp process_message(%Message{text: text}, :idle) when not is_nil(text) do
    {:ok, :idle}
  end

  defp process_message(%Message{}, :idle) do
    {:ok, :skip}
  end
end
