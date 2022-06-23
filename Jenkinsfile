#!groovy

node {

    def SF_CONSUMER_KEY=env.SF_CONSUMER_KEY_COMDEV
    def SF_USERNAME=env.SF_USERNAME_COMDEV
    def SERVER_KEY_CREDENTIALS_ID=env.SERVER_KEY_CREDENTIALS_ID_COMDEV
    def SF_INSTANCE_URL = env.SF_INSTANCE_URL_COMDEV ?: "https://login.salesforce.com"
	def DELTACHANGES = 'deltachanges'
	def DEPLOYDIR = 'toDeploy'
	def APIVERSION = '51.0'
    def toolbelt = tool 'toolbelt'
	def scannerHome = tool 'SonarScanner'
	
	//----------------------------------------------------------------------
	//Check if Previous and Latest commit IDs are provided.
	//----------------------------------------------------------------------
	
	if ((params.PreviousCommitId == '') || (params.LatestCommitId == ''))
	{
		error("Please enter both Previous and Latest commit IDs")
	}


	//----------------------------------------------------------------------
	//Check if Previous and Latest commit IDs are same.
	//----------------------------------------------------------------------
	
	if (params.PreviousCommitId == params.LatestCommitId)
	{
		error("Previous and Latest Commit IDs can't be same.")
	}

	
	//----------------------------------------------------------------------
	//Check if Test classes are mentioned in case of RunSpecifiedTests.
	//----------------------------------------------------------------------
		
	if (TESTLEVEL=='RunSpecifiedTests')
	{
		if (params.SpecifyTestClass == '')
		{
			error("Please Specify Test classes")
		}
	}
	

    stage('Clean Workspace') {
        try {
            deleteDir()
        }
        catch (Exception e) {
            println('Unable to Clean WorkSpace.')
        }
    }
    // -------------------------------------------------------------------------
    // Check out code from source control.
    // -------------------------------------------------------------------------

    stage('checkout source') {
        checkout scm
    }


    // -------------------------------------------------------------------------
    // Run all the enclosed stages with access to the Salesforce
    // JWT key credentials.
    // -------------------------------------------------------------------------

 	withEnv(["HOME=${env.WORKSPACE}"]) {	
	
	    withCredentials([file(credentialsId: SERVER_KEY_CREDENTIALS_ID, variable: 'server_key_file')]) {
		// -------------------------------------------------------------------------
		// Authenticate to Salesforce using the server key.
		// -------------------------------------------------------------------------

		stage('Authorize to Salesforce') {
			rc = command "${toolbelt}/sfdx force:auth:logout --targetusername ${SF_USERNAME} -p"
			rc = command "${toolbelt}/sfdx force:auth:jwt:grant --instanceurl ${SF_INSTANCE_URL} --clientid ${SF_CONSUMER_KEY} --jwtkeyfile ${server_key_file} --username ${SF_USERNAME} --setalias ${SF_USERNAME}"
		    if (rc != 0) {
			error 'Salesforce org authorization failed.'
		    }
		}


	stage('Install PowerKit')
	{
		bat "echo y | sfdx plugins:install sfpowerkit"
	}

		stage('Delta changes')
		{
			script
            {
				rc = command "${toolbelt}/sfdx sfpowerkit:project:diff --revisionfrom %PreviousCommitId% --revisionto %LatestCommitId% --output ${DELTACHANGES} --apiversion ${APIVERSION} -x"
                 
				def folder = fileExists 'DeltaChanges/force-app'
				def file = fileExists 'DeltaChanges/destructiveChanges.xml'
    
				if( folder && !file )
				{
					dir("${WORKSPACE}/${DELTACHANGES}")
					{
						println "Force-app folder exist, destructiveChanges.xml doesn't exist"
						rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
					}
				} 
				else if ( !folder && file ) 
				{
					bat "copy destructive\\package.xml ${DELTACHANGES}"
					println "Force-app folder doesn't exist, destructiveChanges.xml exist" 
				}
				else if ( folder && file ) 
				{
					dir("${WORKSPACE}/${DELTACHANGES}")
					{
						println "Force-app folder exist, destructiveChanges.xml exist"
						if (Deployment_Type=='Deploy Only')
						{
							println "You selected deploy only so deleting destructivechanges.xml to avoid component deletion."
							bat "del /f destructiveChanges.xml"
							rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
						}
						else if (Deployment_Type=='Delete and Deploy')
						{
							println "Both deletion and deployment will be performed."
							rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
							bat "copy destructiveChanges.xml ..\\${DEPLOYDIR}"
						}
						else if (Deployment_Type=='Delete Only')
						{
							println "You selected Delete only but force-app folder also exist. So deleting the force-app folder to avoid deployment."
							bat "echo y | rmdir /s force-app"
							bat "copy ..\\destructive\\package.xml ."
						}
						else if (Deployment_Type=='Validate Only')
                        {
                            println "You selected Validate Only, so only validation will be performed."
                            rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
                        }
					}
				}
				else 
				{
					println "There is nothing to be deployed or deleted."
				}
				
               
            }
        }

		stage('Validate Only') 
		{
			if (Deployment_Type=='Validate Only')
			{
				script
				{
				
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME} "
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel fatal"
					}
					else if (TESTLEVEL=='RunSpecifiedTests')
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel fatal"
					}
   
					else 
					{
						error 'Validation failed.'
					}
				}
			}
   		}
		

        // -------------------------------------------------------------------------
		// Deploy metadata and execute unit tests.
		// -------------------------------------------------------------------------
		

		stage('Deploy and Run Tests') 
		{
			if (Deployment_Type=='Deploy Only')
			{	
				script
				{
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} "
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel fatal"
					}
					else if (TESTLEVEL=='RunSpecifiedTests') 
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass						
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel fatal"
					}
					else
					{
						error 'Salesforce deployment failed.'
					}
				}
			}
		}

		stage('Delete Components') 
		{
			if (Deployment_Type=='Delete Only')
			{
				bat "copy manifest\\package.xml ${DELTACHANGES}"
				rc = command "${toolbelt}/sfdx force:mdapi:deploy -u ${SF_USERNAME} -d ${DELTACHANGES} -w 10"
				
			}
		}

		stage('Delete and Deploy') 
		{
			if (Deployment_Type=='Delete and Deploy')
			{
				bat "copy ${DELTACHANGES}\\destructiveChanges.xml ${DEPLOYDIR}"
				script
				{
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} "
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel fatal"
					}
					else if (TESTLEVEL=='RunSpecifiedTests') 
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass						
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel fatal"
					}
					else  
					{
						error 'Salesforce deployment failed.'
					}
				}
				
			}
		}
		
		stage('Save Artifacts')
		{
			if (Deployment_Type=='Delete Only')
			{
				
				bat "xcopy ${DELTACHANGES} D:\\Artifacts /EHCI"
			}
			else
			{
				bat "xcopy ${DEPLOYDIR} D:\\Artifacts /EHCI"
			}
		}	
		}
		
		
	}
	
}
		
def command(script) {
    if (isUnix()) {
        return sh(returnStatus: true, script: script);
    } else {
		return bat(returnStatus: true, script: script);
    }
}
