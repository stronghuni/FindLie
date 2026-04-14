# Clean: Python abstract method. `pass` is the language idiom, not a stub.

from abc import ABC, abstractmethod


class PaymentProcessor(ABC):
    @abstractmethod
    def charge(self, amount: int) -> bool:
        """Subclasses implement this."""
        pass

    @abstractmethod
    def refund(self, transaction_id: str) -> bool:
        pass
