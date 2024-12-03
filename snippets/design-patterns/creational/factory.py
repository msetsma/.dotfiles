'''
--- Factory Pattern ---
Use Case: When you want to delegate the responsibility of creating objects to a factory class.
Example: Creating objects with a common interface but different types.
'''

from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def draw(self):
        pass

class Circle(Shape):
    def draw(self):
        return "Drawing a Circle"

class Square(Shape):
    def draw(self):
        return "Drawing a Square"

class ShapeFactory:
    @staticmethod
    def get_shape(shape_type: str) -> Shape:
        if shape_type == "circle":
            return Circle()
        elif shape_type == "square":
            return Square()
        else:
            raise ValueError("Invalid shape type")

# Example Usage
circle = ShapeFactory.get_shape("circle")
print(circle.draw())  # Output: Drawing a Circle
