// Config
class Globals {
   static String GitRepo = 'https://git.aghosp.com/scm/posh/ct.writelog.git'
   static String ModuleName = 'CT.WriteLog'
   static String JenkinsChannel = '#jenkins-channel'
}

// Workflow Steps
node('master') {
  try {
    // notifyBuild('STARTED')

    stage('Stage 0: Clone') {
      git url: Globals.GitRepo
    }
    stage('Stage 1: Clean') {
      posh 'Invoke-Build Clean'
    }
    stage('Stage 2: Analyze') {
      posh 'Invoke-Build Analyze'
    }
    stage('Stage 3: Test') {
      posh 'Invoke-Build RunTests'
      step([$class: 'NUnitPublisher',
        testResultsPattern: '**\\TestResults.xml',
        debug: false,
        keepJUnitReports: true,
        skipJUnitArchiver:false,
        failIfNoResults: true
      ])
      publishHTML (target: [
        allowMissing: false,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: 'artifacts',
        reportFiles: 'TestReport.htm',
        reportName: "PowerShell Test Report"
      ])
      posh 'Invoke-Build ConfirmTestsPassed'
    }
    stage('Stage 4: Archive') {
      posh 'Invoke-Build Archive'
      archiveArtifacts artifacts: "artifacts/${Globals.ModuleName}.zip", onlyIfSuccessful: true
      archiveArtifacts artifacts: "artifacts/${Globals.ModuleName}.*.nupkg", onlyIfSuccessful: true
    }
    stage('Stage 5: Publish') {
      timeout(20) {
        posh 'Invoke-Build Publish'
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  } finally {
    // notifyBuild(currentBuild.result)
  }
}

// Helper function to run PowerShell Commands
def posh(cmd) {
  bat 'powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command "& ' + cmd + '"'
}