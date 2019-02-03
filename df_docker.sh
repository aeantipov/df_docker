# set some environment variables that will be used to replicate the user within the container
export USERID=`id -u`                                            
export USERNAME=`id -un`                                         
export GRPID=`id -g`                                             
export GRPNAME=`id -gn`                                          
export USRHOME=`echo $HOME`                                      
  
# probably won't hurt to keep this in here - this won't do anything if the container is up-to-date               
# docker pull quantumdocker.azurecr.io/qmt_minimal:master

# obviously replace paths as appropriate for yourself
# -v mounts directories into the container. The lower two are to make SLURM work from within.

export PYTHONPATH="$HOME/code/qmt:$HOME/code/qms"

jupyter_commands="source activate py36; 
                  jupyter contrib nbextension install --user; 
                  jupyter nbextension enable codefolding/main; 
                  jupyter nbextension enable scratchpad/main;
                  jupyter nbextension enable notify/notify; 
                  jupyter nbextension enable varInspector/main; 
                  jupyter nbextension enable toc2/main; 
                  jupyter nbextension enable collapsible_headings/main; 
                  jupyter nbextension enable code_prettify/code_prettify; 
                  nohup /usr/local/envs/py36/bin/jupyter notebook --no-browser --port=8888 --ip=0.0.0.0 --NotebookApp.token='' &"

login_commands="useradd -r -u $USERID -d $USRHOME $USERNAME; \
        chown -R $USERNAME /app; 
		cd ${HOME}; 
		su $USERNAME; "
        #su $USERNAME -c '$jupyter_commands'; 
        #pip install jupyter_contrib_nbextensions descartes ;  
        #runuser -l $USERNAME -- /usr/local/envs/py36/bin/jupyter notebook --no-browser --port=8888 --ip=0.0.0.0 --NotebookApp.token=''
        #conda install -c conda-forge -y descartes jupyter_contrib_nbextensions; 

		#runuser -l ${USERNAME} -c 'cd ${HOME}/code/qms; /usr/local/envs/py36/bin/python setup.py develop --prefix ${HOME}'"
	        #mkdir $USRHOME/lib ; \
orig_home="/mnt/c/Users/andrey/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs/home/andrey"
                                             
docker run \
        -v /c/Users/andrey:$HOME\
        -e MKL_NUM_THREADS -e OMP_NUM_THREADS \
        -e USERID -e USERNAME -e GRPID -e GRPNAME -e USRHOME \
   	    -e PYTHONPATH \
        --name df_dev \
        -p 8888:8888 -it \
        df:latest bash -c "${login_commands}" 
#docker rm df_dev
        #-v /c/Users/andrey/btsync/code.btsync:$HOME/code \
