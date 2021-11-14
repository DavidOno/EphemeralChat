defmodule ChatWeb.MyRoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug()
    ChatWeb.Endpoint.subscribe(topic)
    {:ok, assign(
      socket,
      room_id: room_id,
      topic: topic,
      username: username,
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
      #{:noreply, assign(socket, message: message)}
      {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

end
