defmodule Neuro.Model do
  def predict_generated(image_tensor) do
      {model, state} = load!()

      model
      |> Axon.predict(state, image_tensor)
      |> Nx.argmax()
      |> Nx.to_number()
      |> Neuro.Dataset.to_character()
  end

  def predict(path) do
    with %Evision.Mat{} = mat <-
           Evision.imread(path, flags: Evision.Constant.cv_IMREAD_GRAYSCALE()),
         sized_mat <- Evision.resize(mat, {28, 28}) do
      data =
        Evision.Mat.to_nx(sized_mat)
        |> Nx.reshape({1, 28, 28})
        |> List.wrap()
        |> Nx.stack()
        |> Nx.backend_transfer()

      {model, state} = load!()

      model
      |> Axon.predict(state, data)
      |> Nx.argmax()
      |> Nx.to_number()
      |> Neuro.Dataset.to_character()
    end
  end

  def new({channels, height, width}) do
    Axon.input("input_0", shape: {nil, channels, height, width})
    |> Axon.flatten()
    |> Axon.dense(128, activation: :relu)
    |> Axon.dense(36, activation: :softmax)
  end

  def train(model, training_data, validation_data) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adam(0.01))
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.validate(model, validation_data)
    |> Axon.Loop.run(training_data, %{}, compiler: EXLA, epochs: 10)
  end

  def test(model, state, test_data) do
    model
    |> Axon.Loop.evaluator()
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(test_data, state)
  end

  def save!(model, state) do
    contents = Axon.serialize(model, state)

    File.write!(path(), contents)
  end

  def load! do
    path()
    |> File.read!()
    |> Axon.deserialize()
  end

  def path do
    Path.join(Application.app_dir(:neuro, "priv"), "model.axon")
  end
end
