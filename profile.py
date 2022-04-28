"""This is a profile for running pos controller.

It makes use of a single raw PC running Ubuntu 20.04. It should be able to be instantiated on any cluster.

Instructions:
Wait for the profile instance to start, then click on the node in the topology and choose the `shell` menu item.
If this is your first time using this profile, download your CloudLab credentials from the user menu in the top
right and upload them to `/local/repository/cloudlab.pem` on the node.
Also create a file `/local/repository/cloudlab.pwd` containing your CloudLab password on the node.
Now, execute `/local/repository/install.sh`.
The credentials will be copied to `/proj/$PROJECT/$USER/cl/` such that you do not have to upload them again next time.
For more information on pos, check [the documentation](https://i8-testbeds.pages.gitlab.lrz.de/pos/cli/).
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Optional physical type for all nodes.
pc.defineParameter("phystype",  "Optional physical node type",
                   portal.ParameterType.STRING, "",
                   longDescription="Specify a physical node type (m400,m510,etc) " +
                   "instead of letting the resource mapper choose for you.")

# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()

# Check parameter validity.
pc.verifyParameters()

# Add a raw PC to the request.
poscontroller = request.RawPC("poscontroller")
poscontroller.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD"

if params.phystype != "":
	poscontroller.hardware_type = params.phystype

# Automatically run installer script on startup.
# The script will only install pos IF the necessary credentials
# are placed at the correct location. This means that you have
# to run the install script manually the first time you use this
# profile.
poscontroller.addService(pg.Execute(shell="sh", command="/local/repository/wrapper.sh"))

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)
