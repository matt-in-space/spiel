defmodule Resume.RateLimiter do
  use Hammer, backend: :ets
end
