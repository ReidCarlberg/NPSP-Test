public class FinCalc
{

  //TODO: Legacy method.. get rid of this.
  public static Double calculatePayment(Double periodicInterestRate, Double principal, Integer numPeriods){
  
        //TODO: Have a configurable system default in case interestType is not specified.
        return calculateDecliningBalancePayment(periodicInterestRate, principal, numPeriods);
  }
  
  public static Double calculatePayment(Double periodicInterestRate, Double principal, Integer numPeriods, String interestType){
  
        System.debug('caculating payment' + periodicInterestRate + ' ' + principal + ' ' +  numPeriods + ' ' +  interestType);
        //TODO: Have a configurable system default in case interestType is not specified.
        if(interestType == 'Declining Balance'){ 
            return calculateDecliningBalancePayment(periodicInterestRate, principal, numPeriods);
        }else if(interestType == 'Flat'){ 
            return calculateFlatPayment(periodicInterestRate, principal, numPeriods);
        }else if(interestType == 'Interest Only'){
            return calculateInterestOnlyPayment(periodicInterestRate, principal, numPeriods);
        }
        
        //Default is declining balance
        return calculateDecliningBalancePayment(periodicInterestRate, principal, numPeriods);
  }
  
  //TODO: Remove period after confirming it's always one.
  public static Double calculateInterest(Double periodicInterestRate, Double principal, Double period){
      return ((periodicInterestRate/100.0) * principal * period);
  }
  
  /*Flat Interest Rate*/
  private static Double calculateFlatPayment(Double periodicInterestRate, Double principal, Integer numPeriods){
      return (calculateInterest(periodicInterestRate,principal,numPeriods) + principal) / numPeriods;
  }
  
  /*
   *Declining Balance Interest (EMI of Principal and Interest)
   * Also, known as simple fixed rate amortization schedule from http://en.wikipedia.org/wiki/Amortization_schedule
   */
  private static Double calculateDecliningBalancePayment(Double periodicInterestRate, Double principal, Integer numPeriods) {
      return (periodicInterestRate/100.0 * principal *
            Math.pow(1 + periodicInterestRate/100.0, numPeriods))
        / (Math.pow(1 + periodicInterestRate/100.0, numPeriods) - 1);
  } 
  
  /* Declining Balance Interest - Interest in Periodic Payments; Principal at the End */
  private static Double calculateInterestOnlyPayment(Double periodicInterestRate, Double principal, Integer numPeriods) {
      if(numPeriods == 0) return 0.0;      
      return calculateInterest(periodicInterestRate,principal,numPeriods)/numPeriods;
  }
}