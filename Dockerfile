FROM centos
MAINTAINER @supertaihei02

ENV TIMEZONE Asia/Tokyo
ENV LOGINUSER guest
ENV LOGINPW loginpassword

RUN echo ZONE="$TIMEZONE" > /etc/sysconfig/clock && \
    cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
RUN yum update -y && \
    rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# system.
RUN yum -y --enablerepo=remi,remi-php55 install sudo openssh-server syslog ntp
RUN sed -ri "s/^UsePAM yes/#UsePAM yes/" /etc/ssh/sshd_config
RUN sed -ri "s/^#UsePAM no/UsePAM no/" /etc/ssh/sshd_config
RUN mkdir -m 700 /root/.ssh
RUN useradd $LOGINUSER && echo "$LOGINUSER:LOGINPW" | chpasswd
RUN echo "$LOGINUSER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$LOGINUSER
RUN service sshd start
RUN chkconfig sshd on

# httpd
RUN yum -y --enablerepo=remi,remi-php55 install httpd httpd-devel
RUN chmod 755 /var/log/httpd
RUN touch /etc/sysconfig/network
RUN chkconfig httpd on

# php5
RUN yum -y --enablerepo=remi,remi-php55 install php php-devel php-pear php-gd php-mbstring
RUN service httpd start

# mysql
RUN yum -y --enablerepo=remi,remi-php55 install mysql-server php-mysql
RUN service mysqld start && \
    /usr/bin/mysqladmin -u root password "LOGINPW"
RUN chkconfig mysqld on

#monit
RUN yum -y --enablerepo=remi install monit
ADD monit/monit.sshd /etc/monit.d/sshd
ADD monit/monit.httpd /etc/monit.d/httpd
ADD monit/monit.mysqld /etc/monit.d/mysqld
ADD monit/monit.conf /etc/monit.conf
RUN mkdir /var/monit && chmod -R 600 /etc/monit.conf

EXPOSE 22 80 2812

CMD ["/usr/bin/monit", "-I"]
