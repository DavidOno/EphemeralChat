defmodule ChatWeb.MyRoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug()
    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
      Logger.info("Mount of #{username}")
    end
    Logger.info("Mount2 of #{username}")
    {:ok, assign(
      socket,
      room_id: room_id,
      topic: topic,
      username: username,
      user_list: [],
      message: "",
      messages: [%{uuid: UUID.uuid4(), content: "#{username} joined the chat", username: "system"}],
      temporary_assigns: [messages: []])}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    Logger.info("Submitted: #{message}")
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    ChatWeb.Endpoint.broadcast!(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
      Logger.info("Typed: #{message}")
      {:noreply, assign(socket, message: message)}
      #{:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages = joins |> Map.keys() |> Enum.map(fn username -> %{uuid: UUID.uuid4(), content: "#{username} joined", username: "system"} end)
    leave_messages = leaves |> Map.keys() |> Enum.map(fn username -> %{uuid: UUID.uuid4(), content: "#{username} left", username: "system"} end)

    user_list = ChatWeb.Presence.list(socket.assigns.topic) |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

end
