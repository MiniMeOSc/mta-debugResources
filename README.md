# Debugging Resources for Multi Theft Auto: San Andreas
This repository contains various debugging resources for Multi Theft Auto: San Andreas.

## vehicleComponents
<img width="289" alt="vehicleComponentsGui" src="https://github.com/user-attachments/assets/222dd042-c3cb-4cc1-8ea5-2960bc384245">

vehicleComponents provides a GUI to list all components of the vehicle returned by the script function [getVehicleComponents](https://wiki.multitheftauto.com/wiki/GetVehicleComponents). It allows to show/hide the individual components. The list can be filtered ([Lua pattern matching](https://www.lua.org/pil/20.1.html) can be used).
Vehicle components are hidden client side and are synced to other players via the server.

The GUI can be opened by pressing 9 (above the letters) or executing the command `vehicleComponentGui`.

## effectsTest
<img width="116" alt="effectGui" src="https://github.com/user-attachments/assets/055e9cc8-8afa-4049-8df8-79971b509254">

effectsTest provides a GUI to spawn effects using the [createEffect](https://wiki.multitheftauto.com/wiki/CreateEffect) script function. After being spawned (relative to the player), the properties of the effect (position and rotation) can be manipulated to allow for fine tuned positioning. Using the _useful function_ [attachEffect](https://wiki.multitheftauto.com/wiki/AttachEffect) from the MTA Wiki they can also be indirectly attached to the player or vehicle they're driving.

Effects are spawned client side and not synced to other players via the server.

The GUI can be opened by pressing 8 (above the letters) or executing the command `effectGui`.