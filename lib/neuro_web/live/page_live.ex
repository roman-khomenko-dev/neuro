defmodule NeuroWeb.PageLive do
  use NeuroWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(input: nil)
     |> assign(prediction: nil)
     |> assign(:image, [])
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(prediction: nil)
     |> push_event("reset", %{})}
  end

  def handle_event("predict", %{"character" => character} = _params, socket) do
    prediction =
      character
      |> Neuro.Dataset.generate_image()
      |> Neuro.Model.predict_generated()

    :ok = Neuro.Dataset.clean_uploads()
    {:noreply, socket |> assign(prediction: prediction) |> assign(input: character)}
  end

  def render(assigns) do
    ~H"""
    <.form for={%{}} phx-submit="predict">
      <.input type="text" name="character" value="" />
      <button>Save</button>
    </.form>
    <div>
      <button phx-click="reset">Reset</button>
    </div>

    <%= if @prediction do %>
      <div>
        Input: <%= @input %>
        <div>
          Prediction:
        </div>
        <div>
          <%= @prediction %>
        </div>
      </div>
    <% end %>
    """
  end
end
