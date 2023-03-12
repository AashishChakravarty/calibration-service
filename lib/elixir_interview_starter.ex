defmodule ElixirInterviewStarter do
  @moduledoc """
  See `README.md` for instructions on how to approach this technical challenge.
  """

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  use GenServer

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_args) do
    GenServer.start_link(ElixirInterviewStarter, %CalibrationSession{},
      name: ElixirInterviewStarter
    )
  end

  @spec start(user_email :: String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Creates a new `CalibrationSession` for the provided user, starts a `GenServer` process
  for the session, and starts precheck 1.

  If the user already has an ongoing `CalibrationSession`, returns an error.
  """

  def start(user_email) do
    with %CalibrationSession{user_email: _user_email} = result <-
           GenServer.call(ElixirInterviewStarter, {:start, user_email}) do
      {:ok, result}
    else
      res -> {:error, res}
    end
  end

  @spec start_precheck_2(user_email :: String.t()) ::
          {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Starts the precheck 2 step of the ongoing `CalibrationSession` for the provided user.

  If the user has no ongoing `CalibrationSession`, their `CalibrationSession` is not done
  with precheck 1, or their calibration session has already completed precheck 2, returns
  an error.
  """
  def start_precheck_2(user_email) do
    with "Calibration successful." = result <-
           GenServer.call(ElixirInterviewStarter, {:start_precheck_2, user_email}) do
      {:ok, result}
    else
      res -> {:error, res}
    end
  end

  @spec get_current_session(user_email :: String.t()) :: {:ok, CalibrationSession.t() | nil}
  @doc """
  Retrieves the ongoing `CalibrationSession` for the provided user, if they have one
  """
  def get_current_session(user_email) do
    GenServer.call(ElixirInterviewStarter, {:current_session, user_email})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:start, user_email}, _from, state) when state.user_email == user_email,
    do: {:reply, "already ongoing calibration session", state}

  @impl true
  def handle_call({:start, user_email}, _from, state) do
    case DeviceMessages.send(user_email, "startPrecheck1") do
      %{"precheck1" => true} ->
        state =
          state
          |> Map.put(:user_email, user_email)
          |> Map.put(:precheck1, true)

        {:reply, state, state}

      %{"precheck1" => _} ->
        {:stop, :precheck1_failed, "precheck 1 failed.", state}

      _ ->
        {:stop, :precheck1_timeout, "precheck 1 timed out.", state}
    end
  end

  @impl true
  def handle_call({:start_precheck_2, user_email}, _from, state)
      when state.user_email != user_email,
      do: {:reply, "no ongoing calibration session for user", state}

  @impl true
  def handle_call({:start_precheck_2, _user_email}, _from, state)
      when is_nil(state.precheck1),
      do: {:reply, "precheck1 is not completed", state}

  @impl true
  def handle_call({:start_precheck_2, user_email}, _from, state) do
    case DeviceMessages.send(user_email, "startPrecheck2") do
      %{"cartridgeStatus" => true, "submergedInWater" => true} ->
        calibrate(user_email, state)

      %{"cartridgeStatus" => _, "submergedInWater" => _} ->
        {:stop, :precheck2_failed, "Precheck2 failed.", state}

      _ ->
        {:stop, :precheck2_timeout, "Precheck2 timed out.", state}
    end
  end

  @impl true
  def handle_call({:current_session, user_email}, _from, state) do
    value = if state.user_email == user_email, do: state, else: nil
    {:reply, value, state}
  end

  def calibrate(user_email, state) when state.user_email == user_email do
    case DeviceMessages.send(user_email, "calibrate") do
      %{"calibrated" => true} ->
        {:stop, :normal, "Calibration successful.", state}

      %{"calibrated" => _} ->
        {:stop, :calibration_failed, "Calibration failed.", state}

      _ ->
        {:stop, :calibration_timeout, "Calibration timed out.", state}
    end
  end

  def calibrate(_user_email, state),
    do: {:stop, :not_found, "Calibration service not found.", state}
end
