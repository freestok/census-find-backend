FROM virtualstaticvoid/heroku-docker-r:plumber

# ONBUILD will copy application files into the container
#  and execute init.R (if it exists) and restore packrat packages (if they exist)

# provide the port for Plumber, so that running/testing outside of Heroku is possible
# Heroku will override the PORT value at runtime
ENV PORT=8080

# install dependencies
RUN apt-get install -y libudunits2-dev

# override the base image CMD to run Plumber
CMD ["/usr/bin/R", "--no-save", "--gui-none", "-f", "/app/app.R"]
