simulate_ddemand <-
function(model, hdata, simyears=1000, delta=5)
{
	periods <- length(unique(hdata$timeofday))

	# Generate nsim years of adjusted log demand
	nh <- nrow(hdata)
	nhdata <- trunc(nrow(hdata)/seasondays/periods + 0.9999)
	nsim <- trunc(simyears/nhdata + 0.9999)
	nyears <- nsim*nhdata    # actual years to be simulated
	hfit.sim <- hres.sim <- ores <- temp.sim <- matrix(NA,seasondays*periods,nyears)
	for(i in 1:nsim){
		# Simulated adjusted log demand
		tmp <- newpredict(model,hdata,blocklength=35,delta=delta,periods=periods)
		hfit <- tmp$hfit
		#hres <- tmp$hres
		simtemp <- tmp$simtemp
		
		# Half hourly residuals (done with the temperature simulation)
		hres <- simulate_res(hdata,model,35,hfit,periods=periods) # still use the original residual simulation

 		# fix partial data at the end if any, copy and paste the corresponding part of the last year
		if((nhdata*seasondays*periods-nh)!=0){
			hfit <- c(hfit,hfit[(length(hfit)-seasondays*periods) + 1:(nhdata*seasondays*periods-nh)])
			hres <- c(hres,hres[(length(hres)-seasondays*periods) + 1:(nhdata*seasondays*periods-nh)])
		}
       
		##############################################################
		# fix partial data at the end if any, copy and paste the corresponding part of the last year
		if((nhdata*seasondays*periods-nh)!=0)
			simtemp <- c(simtemp,simtemp[(length(simtemp)-seasondays*periods) + 1:(nhdata*seasondays*periods-nh)])
		temp.sim[,(i-1)*nhdata + 1:nhdata] <- matrix(simtemp,nrow=seasondays*periods,ncol=nhdata,byrow=F)
		##############################################################
        
		hfit.sim[,(i-1)*nhdata + 1:nhdata] <- matrix(hfit,nrow=seasondays*periods,ncol=nhdata,byrow=F)
		hres.sim[,(i-1)*nhdata + 1:nhdata] <- matrix(hres,nrow=seasondays*periods,ncol=nhdata,byrow=F)

		# simple seasonal bootstrap for offset demand: season.bootstrap()
		ores[,(i-1)*nhdata + 1:nhdata] <- matrix(season.bootstrap(hdata$doffset[20000:nh],20,n=nhdata*seasondays*periods,periods),
			nrow=seasondays*periods,ncol=nhdata,byrow=F)
	}

	return(structure(list(hhfit=ts(hfit.sim[,1:simyears],frequency=periods,start=1),
		hhres=ts(hres.sim[,1:simyears],frequency=periods,start=1),
		ores=ts(ores[,1:simyears],frequency=periods,start=1),a=model$a),class="simdemand"))
}
