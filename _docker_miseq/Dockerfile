# Use the official Python 3.10 image as the base image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Update package index and install required packages
RUN apt-get update -y && \
    apt-get install -y vim wget gcc zlib1g-dev make git dos2unix gzip

RUN apt-get update \
  && apt-get -y install build-essential \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/* \
  && wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /opt/cmake-3.24.1 \
      && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.24.1 \
      && rm /tmp/cmake-install.sh \
      && ln -s /opt/cmake-3.24.1/bin/* /usr/local/bin

# Clone OBITools3 repository
RUN git clone https://git.metabarcoding.org/obitools/obitools3.git

# Create and activate virtual environment
RUN python3 -m venv obi3-env && \
    . obi3-env/bin/activate

# Install Cython
RUN obi3-env/bin/pip install cython

# Install OBITools3
RUN . obi3-env/bin/activate && \
    cd obitools3 && \
    python3 setup.py install && \
    cd ..

# Install Cutadapt
RUN obi3-env/bin/pip install cutadapt

# Install FLASH
RUN wget https://downloads.sourceforge.net/project/flashpage/FLASH-1.2.11.tar.gz && \
    tar -xzf FLASH-1.2.11.tar.gz && \
    cd FLASH-1.2.11 && \
    make && \
    cp flash /usr/local/bin/ && \
    cd .. && \
    rm -rf FLASH-1.2.11 && \
    rm FLASH-1.2.11.tar.gz

# Install Sabre
RUN git clone https://github.com/najoshi/sabre.git && \
    cd sabre && \
    make && \
    cp sabre /usr/local/bin/ && \
    cd .. && \
    rm -rf sabre

# Update PATH variable
ENV PATH="/app/obitools3/bin:${PATH}"

# Add obi command to PATH
RUN echo 'export PATH="$PATH:/app/obitools3/bin"' >> ~/.bashrc

# Configure OBITools3 auto-completion (optional)
RUN echo "source /app/obitools3/obi_completion_script.bash" >> ~/.bashrc


# Copy files and convert line endings
COPY welcome.sh sabre_test.sh test_fwd.fastq test_rev.fastq samples_multiplex.txt /app/
RUN dos2unix /app/welcome.sh /app/sabre_test.sh && \ 
    dos2unix /app/test_fwd.fastq /app/test_rev.fastq /app/samples_multiplex.txt

COPY R_demux.sh R_species_determination.sh /app/
RUN dos2unix /app/R_demux.sh /app/R_species_determination.sh

COPY R1.fastq.gz R2.fastq.gz R_samplesheet.smp demux_annelies.sh /app/
RUN dos2unix /app/demux_annelies.sh && \
    gzip -d /app/R1.fastq.gz && \
    gzip -d /app/R2.fastq.gz

RUN chmod +x /app/demux_annelies.sh && \
    cd /app && \
    ./demux_annelies.sh -b R_samplesheet.smp -f R1.fastq -r R2.fastq    


# Set the command to run your Bash script
#CMD ["/bin/bash", "-c", "source /app/obi3-env/bin/activate && /app/welcome.sh && exec tail -f /dev/null"]
#CMD ["/bin/bash", "-c", "source /app/obi3-env/bin/activate && /app/welcome.sh && exec /bin/bash"]
CMD ["/bin/bash", "-c", "source /app/obi3-env/bin/activate  && exec tail -f /dev/null"]
