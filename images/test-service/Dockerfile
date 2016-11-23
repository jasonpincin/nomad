FROM node:6.7

# copy our application
COPY package.json /opt/service/
COPY server.js /opt/service/

EXPOSE 5000
CMD [ "node", "/opt/service/server.js" ]
