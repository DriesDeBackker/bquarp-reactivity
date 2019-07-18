alias Observables.{Obs, Subject}
alias Reactivity.Registry
alias Reactivity.DSL.{Signal, SignalObs, Behaviour, EventStream}
import Deployment

require Logger

#####################
# DEPLOYMENT SCRIPT #
#####################

# In this example we deploy a simple distributed reactive application
# to a series of Raspberry Pi nodes.
# Specifically, it is the example reactive program from the QUARP paper.
# Mock data simulates sensor measurements.

# Activate the program as follows:
# - Start the QUARP middleware and spawn an iex shell
#   iex --name bob@pc -S mix
#   (If not automatically connected with the rpis, connect manually:
#   Network.Connector.manual_connect_and_subscribe([rpi1, rpi2, rpi3]))
# - Load this script:
#   import_file("path/to/this_script.exs")

# The fully qualified names of the rpi nodes:
rpi1= :"nerves@192.168.1.5"
rpi2= :"nerves@192.168.1.4"
rpi3= :"nerves@192.168.1.3"

temperature1_app = fn ->
	# Create a handle for the source signal
	t1_handle = Subject.create
	# Create a source signal out of it
	_t1 = t1_handle
	|> Behaviour.from_plain_obs
	|> Behaviour.register(:t1)
	|> Signal.inspect
	# Use the handle to generate new source data
	#  Here, we just generate mock data
	Obs.repeat(fn -> Enum.random(0..35) end)
	|> Obs.each(fn v -> Subject.next(t1_handle, v) end)
	:ok
end

deploy(rpi1, temperature1_app)