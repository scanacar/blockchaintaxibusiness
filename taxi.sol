pragma solidity >=0.4.0 <0.6.0;

contract SharedTaxiBusiness{
    
    ////// State Variable ///////
    
    uint contractBalance;
    uint fixedExpenses;
    uint participationFee;
    mapping (uint => Participant) participants; // unique indexed participant array
    address Manager;  // contracts caller
    address carDealer;
    uint public personCount;
    int32 ownedCar;
    address this;
    
    //////// Time variables ///////
    
    uint offerCurrentTime;
    uint purchaseCurrentTime;
    
    //////// Variables ///////
    
    bool controlForDriver;
    uint timeForDriverSalary;
    uint charge;
    uint releasedSalary;
    uint timeForCarExpenses;
    uint maintenanceAndTax;
    
    //////// Structs ////////
    
    struct Participant {
        uint pId;
        address pAddress;
        uint balance;
    }
    
    struct Driver {
        address dAddress;
        uint salary;
    }
    Driver candidateDriver;
    Driver driver;
    
    struct ProposedCar {
        int32 CarID;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }
    ProposedCar proposedCar;
    
    struct ProposedRepurchase {
        int32 CarID;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }
    ProposedRepurchase proposedRepurchase;
    
    /////// Constructor for initial values of state variables /////////
    
    constructor() public{
        Manager = msg.sender;
        contractBalance = 0 ether;
        fixedExpenses = 10 ether;
        participationFee = 100 ether;
        personCount = 0;
        controlForDriver = false;
        charge = 50 ether;
        releasedSalary = 0;
        maintenanceAndTax = now;
        
    }
    
    //////// Modifiers //////////
    
    modifier onlyParticipants {
        
        bool isParticipant = false;
        for (uint i = 0; i <= personCount; i++){
            if (msg.sender == participants[i].pAddress)
                isParticipant == true;
        }
        if (isParticipant == true){
            _;   
        }
    }
    
    modifier onlyCandidateParticipants { // control the address is exists
                                         
        bool isParticipant = false;
        for (uint i=0; i<= personCount; i++){
            if (msg.sender == participants[i].pAddress)
                isParticipant == true;
        }
        if (isParticipant == false && personCount < 10){  // personCount cant be above 9
            _;
        }
    }
    
    modifier onlyManager {
        if (msg.sender == carDealer) {
            _;
        }
    }
    
    modifier onlyCarDealer {
        if (msg.sender == carDealer) {
            _;
        }
    }
    
    modifier onlyDriver {
        
        if (msg.sender == driver.dAddress) {
            _;
        }
    }
    
    
    ///////// Functions /////////
    
    function Join () public payable onlyCandidateParticipants {
        
        if (msg.value >= participationFee) {
            
            this.transfer(participationFee);
            contractBalance += participationFee;
            participants[personCount] = Participant(personCount,msg.sender,msg.value);
            personCount++;
        }
    }
    
    function setCarDealer (address carDealerAddress) public onlyManager {
        
        carDealer = carDealerAddress;
    }
    
    function carProposeToBusiness (int32 CarID, uint price, uint offerValidTime) public onlyCarDealer {
        
        proposedCar.CarID = CarID;
        proposedCar.price = price;
        proposedCar.offerValidTime = offerValidTime;
        proposedCar.approvalState = 0;
        offerCurrentTime = now;
    }
    
    address[] controlDoubleVote;  // for each participant can increment once rule
    uint public votes = 0;        // votes count
    
    function approvePurchaseCar () public onlyParticipants returns(bool) {
        
        for (uint i=0; i < controlDoubleVote.length; i++){
            if (msg.sender == controlDoubleVote[i]) return false;
        }
        
        controlDoubleVote.push(msg.sender);
        votes += 1;
        
        return true;
    }
    
    function purchaseCar () public payable onlyManager {
        
        if (proposedCar.offerValidTime + offerCurrentTime >= now &&
        (votes > (personCount/2) ) ) {
            contractBalance -= proposedCar.price;
            carDealer.transfer(proposedCar.price);
            
            for (uint i=0 ; i < controlDoubleVote.length; i++){
                delete controlDoubleVote[i];
            }
            
            timeForCarExpenses = now;
            votes = 0;
        }
    }
    
    function repurchaseCarPropose (int32 CarID, uint price, uint offerValidTime) public onlyCarDealer {
        
        proposedRepurchase.CarID = CarID;
        proposedRepurchase.price = price;
        proposedRepurchase.offerValidTime = offerValidTime;
        proposedRepurchase.approvalState = 0;
        purchaseCurrentTime = now;
    }
    
    address[] controlDoubleVoteForSell;  // for each participant can increment once rule
    uint public votesForSell = 0;        // votes count
    
    function approveSellProposal () public onlyParticipants returns(bool) {
        
        for (uint i=0; i < controlDoubleVoteForSell.length; i++){
            if (msg.sender == controlDoubleVoteForSell[i]) return false;
        }
        
        controlDoubleVoteForSell.push(msg.sender);
        votesForSell += 1;
        
        return true;
    }
    
    function repurchaseCar () public payable onlyCarDealer {
        
        if ( (votes > (personCount/2) ) && (proposedRepurchase.offerValidTime + purchaseCurrentTime) > now ){
            
            contractBalance += proposedRepurchase.price;
            this.transfer(proposedRepurchase.price);
            controlDoubleVoteForSell;
            
            for (uint i=0; i < controlDoubleVoteForSell.length; i++){
                delete controlDoubleVoteForSell[i];
            }
            
            votesForSell = 0;
        }
    }
    
    function proposeDriver (address dAddress, uint salary) public onlyManager {
        
        candidateDriver.dAddress = dAddress;
        candidateDriver.salary = salary;
    }
    
    address[] controlDoubleVoteForDriver;
    uint public votesForDriver = 0;
    
    
    function approveDriver () public onlyParticipants {
        
        for (uint i=0; i < controlDoubleVoteForDriver.length; i++){
            if (msg.sender == controlDoubleVoteForDriver[i]) return;
        }
        
        controlDoubleVoteForDriver.push(msg.sender);
        votesForDriver += 1;
        
        return;
    }
    
    function setDriver () public onlyManager {
        
        if (votesForDriver > (personCount/2) ){
            
            driver.dAddress = candidateDriver.dAddress;
            driver.salary = candidateDriver.salary;
            
            for (uint i=0; i < controlDoubleVoteForDriver.length; i++){
                delete controlDoubleVoteForDriver[i];
            }
            
            controlForDriver = true;
            votesForDriver = 0;
        }
    }

    function fireDriver () public payable onlyManager {
        
        if (controlForDriver == true){
            driver.dAddress.transfer(driver.salary);
            driver.dAddress = 0;
            controlForDriver = false;
            timeForDriverSalary = now;
        }
    }

    function payTaxiCharge () public payable {
        
        this.transfer(charge);
        contractBalance += charge;
    }
    
    function releaseSalary () public onlyManager {
        
        if (timeForDriverSalary + 2629743 < now ) {    // 1 month - epoch value 
            
            contractBalance -= driver.salary;
            releasedSalary = driver.salary;
            timeForDriverSalary = now;
        }
    }
    
    function getSalary () public payable onlyDriver {
        
        driver.dAddress.transfer(releasedSalary);
        releasedSalary = 0;
    }
    
    function payCarExpenses () public payable onlyManager {
        
        if ( timeForCarExpenses + 15778458 < now){  // 6 months - epoch value
            
            carDealer.transfer(fixedExpenses);
            contractBalance -= fixedExpenses;
            timeForCarExpenses = now;
        }
    }
    
    uint[] dividendArr;    // dividend value is hold
    
    function payDividend () public onlyManager {
        
        if (maintenanceAndTax + 15778458 < now){
            
            uint division = contractBalance / personCount;
            
            for (uint i =0; i < personCount; i++){
                dividendArr[i] += division;
            }
            
            maintenanceAndTax = now;
        }
    }
    
    function getDividend () public payable onlyParticipants {
        
        uint dividend = contractBalance / personCount;
        
        for (uint i=0; i < personCount; i++){
            
            if (msg.sender == participants[i].pAddress){
                
                msg.sender.transfer(dividendArr[i]);
                participants[i].balance += dividend;
                dividendArr[i] = 0;
            }
        }
        
       
    }
    
    function () external {   // Fallback
        
        revert();
    }
    
    
}