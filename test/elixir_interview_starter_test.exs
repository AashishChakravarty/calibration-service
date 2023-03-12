defmodule ElixirInterviewStarterTest do
  use ExUnit.Case, async: false

  alias ElixirInterviewStarter.CalibrationSession

  @user_email "asdf@asdf.com"

  test "it can go through the whole flow happy path" do
    ElixirInterviewStarter.start(@user_email)

    assert ElixirInterviewStarter.start_precheck_2(@user_email) ==
             {:ok, "Calibration successful."}
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
    assert ElixirInterviewStarter.start(@user_email) ==
             {:ok, %CalibrationSession{user_email: @user_email, precheck1: true}}
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
    ElixirInterviewStarter.start(@user_email)

    assert ElixirInterviewStarter.start(@user_email) ==
             {:error, "already ongoing calibration session"}
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
    assert ElixirInterviewStarter.start_precheck_2("asdf1@asdf.com") ==
             {:error, "no ongoing calibration session for user"}
  end

  test "get_current_session/1 returns the provided user's ongoing calibration session" do
    ElixirInterviewStarter.start(@user_email)

    assert ElixirInterviewStarter.get_current_session(@user_email) ==
             %CalibrationSession{user_email: @user_email, precheck1: true}
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibrationo session" do
    assert ElixirInterviewStarter.get_current_session("asdf1@asdf.com") == nil
  end
end
