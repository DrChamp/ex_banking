defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @doc """
  Hello world.
  """
  alias ExBanking.User
  alias ExBanking.UserSupervisor

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    case UserSupervisor.new_user(user) do
      {:ok, _pid} -> :ok
      error -> error
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_integer(amount) and amount >= 0 and is_binary(currency) do
    User.request(user, {:deposit, amount, currency})
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_integer(amount) and amount >= 0 and is_binary(currency) do
    User.request(user, {:withdraw, amount, currency})
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    User.request(user, {:get_balance, currency})
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_integer(amount) and amount >= 0 and
             is_binary(currency) do
    opts = [
      user_exist_error_msg: :sender_does_not_exist,
      requests_limit_error_msg: :too_many_requests_to_sender
    ]

    User.request(from_user, {:send, to_user, amount, currency}, opts)
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end
