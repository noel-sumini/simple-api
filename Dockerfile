# 베이스 이미지
FROM python:3.11-slim

# 작업 디렉토리 생성
WORKDIR /app

# 의존성 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사
COPY app ./app

# 컨테이너 run할때 실행할 커맨드
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "18080"]