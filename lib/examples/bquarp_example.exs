alias Observables.{Obs, Subject}
alias Reactivity.Registry
alias Reactivity.DSL.{Signal, SignalObs, Behaviour, EventStream}
import Deployer

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
rpi1= :"nerves@192.168.1.3"
rpi2= :"nerves@192.168.1.4"
rpi3= :"nerves@192.168.1.5"

# Create a mock temperature sensor
temperature1_app = fn ->
	t1_handle = Subject.create
	t1_handle
	|> EventStream.from_plain_obs({:t, 0})
	|> EventStream.scan(fn(x,y) -> x + y end)
	|> EventStream.hold
	|> Signal.register(:t1)
	|> Signal.inspect
	Subject.next(t1_handle, 20)
	Obs.repeat(fn -> Enum.random(-1..1) end)
	|> Obs.each(fn v -> Subject.next(t1_handle, v) end)
	:ok
end

# Create a mock temperature sensor
temperature2_app = fn ->
	t2_handle = Subject.create
	t2_handle
	|> EventStream.from_plain_obs({:t, 0})
	|> EventStream.scan(fn(x,y) -> x + y end)
	|> EventStream.hold
	|> Signal.register(:t2)
	|> Signal.inspect
	Subject.next(t2_handle, 20)
	Obs.repeat(fn -> Enum.random(-1..1) end)
	|> Obs.each(fn v -> Subject.next(t2_handle, v) end)
	:ok
end

# Calculate the mean temperature
mean_temperature_app = fn ->
	t1 = Signal.signal(:t1)
	t2 = Signal.signal(:t2)
	tm = Signal.liftapp([t1, t2], fn(x,y) -> (x+y)/2 end)
	|> Signal.register(:tm)
	|> Signal.inspect
	:ok
end

# Control an air conditioning unit
#airco_app = fn ->
#	tm = 
#		Signal.signal(:tm)
#		|> Behaviour.changes
#	commands = 
#		tm
#		|> EventStream.filter(fn t -> t > 25 or t < 20 end)
#		|> EventStream.liftapp(fn t -> if t > 25, do: :on, else: :off end)
#		|> EventStream.novel
#		|> EventStream.each(
#			fn c ->
#				case c do
#					:off -> false
#					:on -> true
#				end
#			end)
#	:ok
#end

deploy(rpi1, temperature1_app)
deploy(rpi2, temperature2_app)
deploy(rpi2, mean_temperature_app)
#deploy(rpi3, airco_app)
