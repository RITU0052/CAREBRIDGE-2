import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

raw_url = os.environ.get("DATABASE_URL", "").strip()
if raw_url:
    SQLALCHEMY_DATABASE_URL = raw_url
elif os.environ.get("VERCEL") or os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
    SQLALCHEMY_DATABASE_URL = "sqlite:////tmp/carebridge.db"
else:
    SQLALCHEMY_DATABASE_URL = "sqlite:///./carebridge.db"

# In SQLite, setting check_same_thread=False is needed for FastAPI
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
