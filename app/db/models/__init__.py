"""ORM model registry — import all models here so Alembic can discover them."""

from app.db.models.advisory import Advisory
from app.db.models.alert import Alert
from app.db.models.crop import Crop
from app.db.models.log import Log
from app.db.models.media import Media
from app.db.models.model_registry import ModelRegistry
from app.db.models.pond import Pond
from app.db.models.user import User

__all__ = ["Advisory", "Alert", "Crop", "Log", "Media", "ModelRegistry", "Pond", "User"]
