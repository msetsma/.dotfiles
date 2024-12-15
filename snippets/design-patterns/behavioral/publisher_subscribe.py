"""
--- Publish-Subscribe Pattern ---
Use Case: Decouple components by allowing subscribers to listen to events published by a central hub.
Example: Real-time messaging systems, logging frameworks, or analytics.
Description: The Pub-Sub Pattern facilitates communication between publishers and subscribers
through a central mediator (event hub), allowing multiple subscribers to react to published events.
"""

from typing import Callable, Dict, List

class EventHub:
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}

    def subscribe(self, topic: str, callback: Callable):
        """Subscribe a callback function to a specific topic."""
        if topic not in self.subscribers:
            self.subscribers[topic] = []
        self.subscribers[topic].append(callback)
        print(f"Subscribed to topic: {topic}")

    def unsubscribe(self, topic: str, callback: Callable):
        """Unsubscribe a callback function from a specific topic."""
        if topic in self.subscribers and callback in self.subscribers[topic]:
            self.subscribers[topic].remove(callback)
            print(f"Unsubscribed from topic: {topic}")

    def publish(self, topic: str, message: str):
        """Publish a message to all subscribers of a specific topic."""
        if topic not in self.subscribers or not self.subscribers[topic]:
            print(f"No subscribers for topic: {topic}")
            return
        print(f"Publishing message to topic: {topic}")
        for callback in self.subscribers[topic]:
            callback(message)

# Example subscriber functions
def subscriber_one(message: str):
    print(f"Subscriber One received: {message}")

def subscriber_two(message: str):
    print(f"Subscriber Two received: {message}")

# Example usage
def main():
    hub = EventHub()

    # Subscribe functions to topics
    hub.subscribe("topic1", subscriber_one)
    hub.subscribe("topic1", subscriber_two)
    hub.subscribe("topic2", subscriber_two)

    # Publish messages
    hub.publish("topic1", "Hello from topic1!")
    hub.publish("topic2", "Hello from topic2!")
    hub.publish("topic3", "Hello from topic3!")  # No subscribers

    # Unsubscribe and publish again
    hub.unsubscribe("topic1", subscriber_two)
    hub.publish("topic1", "Another message for topic1!")

if __name__ == "__main__":
    main()

# Output
# Subscribed to topic: topic1
# Subscribed to topic: topic1
# Subscribed to topic: topic2
# Publishing message to topic: topic1
# Subscriber One received: Hello from topic1!
# Subscriber Two received: Hello from topic1!
# Publishing message to topic: topic2
# Subscriber Two received: Hello from topic2!
# No subscribers for topic: topic3
# Unsubscribed from topic: topic1
# Publishing message to topic: topic1
# Subscriber One received: Another message for topic