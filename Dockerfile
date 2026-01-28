FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files from backend folder
COPY backend/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the backend code
COPY backend/ .

# Expose the port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
