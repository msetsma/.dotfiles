'''
--- Command Pattern ---
Use Case: Encapsulate requests or operations as objects to allow undoable actions or queuing.
Example: Task queues, undo/redo functionality, or macro recording.
'''

class Command:
    def execute(self):
        pass

    def undo(self):
        pass

class Light:
    def on(self):
        print("The light is ON")

    def off(self):
        print("The light is OFF")

class LightOnCommand(Command):
    def __init__(self, light: Light):
        self.light = light

    def execute(self):
        self.light.on()

    def undo(self):
        self.light.off()

class LightOffCommand(Command):
    def __init__(self, light: Light):
        self.light = light

    def execute(self):
        self.light.off()

    def undo(self):
        self.light.on()

# Example Usage
light = Light()
on_command = LightOnCommand(light)
off_command = LightOffCommand(light)

on_command.execute()  # Output: The light is ON
on_command.undo()     # Output: The light is OFF
