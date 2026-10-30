"""Publish events to the Integration Hub events API.

    import integration_hub_events as events

    events.send("order.created")
    events.send("order.created", {"order_id": 123})

The API endpoint is read from the EVENTS_API_URL environment variable.
"""

from .client import send

__all__ = ["send"]
