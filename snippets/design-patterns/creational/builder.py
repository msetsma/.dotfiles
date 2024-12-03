'''
--- Builder Pattern ---
Use Case: When you need to construct complex objects step by step.
Example: Creating objects with many optional parameters.
'''

class Car:
    def __init__(self):
        self.make = None
        self.model = None
        self.color = None

    def __str__(self):
        return f"{self.color} {self.make} {self.model}"

class CarBuilder:
    def __init__(self):
        self.car = Car()

    def set_make(self, make):
        self.car.make = make
        return self

    def set_model(self, model):
        self.car.model = model
        return self

    def set_color(self, color):
        self.car.color = color
        return self

    def build(self):
        return self.car

# Example Usage
builder = CarBuilder()
car = builder.set_make("Tesla").set_model("Model S").set_color("Red").build()
print(car)  # Output: Red Tesla Model S
