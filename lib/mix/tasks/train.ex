defmodule Mix.Tasks.Train do
  use Mix.Task

  @requirements ["app.start"]

  alias Neuro

  def run(_) do

    data = Neuro.Dataset.generate() |> IO.inspect(label: "dataset")

    model = Neuro.Model.new({1, 28, 28})

    Mix.Shell.IO.info("training...")

    state = Neuro.Model.train(model, data, data)

    Mix.Shell.IO.info("testing...")

    Neuro.Model.test(model, state, data)

    Neuro.Model.save!(model, state)
  end
end
