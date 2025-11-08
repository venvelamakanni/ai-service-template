# --- STAGE 1: The "builder" stage ---
    FROM python:3.10 as builder

    WORKDIR /app
    COPY requirements.txt .
    
    # Install dependencies into a "virtual environment"
    RUN pip wheel --no-cache-dir --wheel-dir=/app/wheels -r requirements.txt
    
    
    # --- STAGE 2: The "final" or "production" stage ---
    FROM python:3.10-slim
    
    WORKDIR /app
    
    # Create a non-root user and group for security
    RUN groupadd -r appgroup && useradd -r -g appgroup appuser
    
    # Copy the application code
    COPY . .
    
    # Copy the pre-built dependencies from the "builder" stage
    COPY --from=builder /app/wheels /wheels
    RUN pip install --no-cache /wheels/*
    
    # Change ownership to our new non-root user
    RUN chown -R appuser:appgroup /app
    
    # Switch to the non-root user
    USER appuser
    
    # Expose the port the app will run on
    EXPOSE 8080
    
    # The command to run the application
    CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]