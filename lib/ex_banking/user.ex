defmodule ExBanking.User do
  @moduledoc """
  This module will create gen_server process for each user
  and it will have all the  which ExBanking have
  """

  defmodule UserAccount do
    @moduledoc """
    This module is just to create a user account struct which
    we will save in process memory
    """
    defstruct currencies: %{}
  end

  use GenServer

  def start_link(user) do
    name = {:via, Registry, {Registry.Users, user}}

    case GenServer.start_link(__MODULE__, [], name: name) do
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
      {:ok, pid} -> {:ok, pid}
    end
  end

  def init(_) do
    {:ok, %UserAccount{}}
  end

  def handle_call({:get_balance, currency}, _from, user_account) do
    {:reply, {:ok, Map.get(user_account.currencies, currency, 0.0)}, user_account}
  end

  def handle_call({:deposit, amount, currency}, _from, user_account) do
    new_balance =
      (Map.get(user_account.currencies, currency, 0.0) + amount)
      |> :erlang.float()
      |> Float.floor(2)

    {:reply, {:ok, new_balance},
     %UserAccount{currencies: Map.put(user_account.currencies, currency, new_balance)}}
  end

  def handle_call({:withdraw, amount, currency}, _from, user_account) do
    old_balance = Map.get(user_account.currencies, currency, 0.0)

    if old_balance - amount < 0 do
      {:reply, {:error, :not_enough_money}, user_account}
    else
      new_balance = (old_balance - amount) |> :erlang.float() |> Float.floor(2)

      {:reply, {:ok, new_balance},
       %UserAccount{currencies: %{user_account.currencies | currency => new_balance}}}
    end
  end

  def handle_call({:send, to_user, amount, currency}, _from, user_account) do
    old_balance = Map.get(user_account.currencies, currency, 0.0)

    if old_balance - amount < 0 do
      {:reply, {:error, :not_enough_money}, user_account}
    else
      opts = [
        user_exist_error_msg: :receiver_does_not_exist,
        requests_limit_error_msg: :too_many_requests_to_receiver
      ]

      case request(to_user, {:deposit, amount, currency}, opts) do
        {:ok, receiver_balance} ->
          sender_balance = (old_balance - amount) |> :erlang.float() |> Float.floor(2)

          {:reply, {:ok, sender_balance, receiver_balance},
           %UserAccount{currencies: %{user_account.currencies | currency => sender_balance}}}

        error ->
          {:reply, error, user_account}
      end
    end
  end

  def request(user, request, opts \\ []) do
    with {:ok, pid} <- user_exist?(user, opts),
         :ok <- requests_limit?(pid, opts) do
      GenServer.call(pid, request)
    end
  end

  def user_exist?(user, opts) do
    case Registry.lookup(Registry.Users, user) do
      [] ->
        error_msg = Keyword.get(opts, :user_exist_error_msg, :user_does_not_exist)
        {:error, error_msg}

      [{pid, _}] ->
        {:ok, pid}
    end
  end

  def requests_limit?(pid, opts) do
    case :erlang.process_info(pid, :message_queue_len) do
      {:message_queue_len, length} when length < 10 ->
        :ok

      _ ->
        error_msg = Keyword.get(opts, :requests_limit_error_msg, :too_many_requests_to_user)
        {:error, error_msg}
    end
  end
end
