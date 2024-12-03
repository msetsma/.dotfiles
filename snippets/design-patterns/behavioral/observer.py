'''
--- Observer Pattern ---
Use Case: When one object needs to notify multiple objects about changes.
Example: Event handling systems like GUIs or real-time updates.
'''

class Subject:
    def __init__(self):
        self._observers = []

    def attach(self, observer):
        self._observers.append(observer)

    def detach(self, observer):
        self._observers.remove(observer)

    def notify(self, message):
        for observer in self._observers:
            observer.update(message)

class Observer:
    def update(self, message):
        raise NotImplementedError

class ConcreteObserver(Observer):
    def update(self, message):
        print(f"Observer received: {message}")

# Example Usage
subject = Subject()
observer1 = ConcreteObserver()
observer2 = ConcreteObserver()

subject.attach(observer1)
subject.attach(observer2)

subject.notify("Event occurred!")  
# Output:
# Observer received: Event occurred!
# Observer received: Event occurred!
