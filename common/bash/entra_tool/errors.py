class AppError(Exception):
    pass


class GraphError(AppError):
    pass


def die(message: str) -> None:
    raise AppError(message)
