// SPDX-License-Identifier: MIT
// SPDX 라이선스 식별자: 소스 코드의 라이선스 유형을 명시합니다. MIT 라이선스는 자유롭게 수정 및 배포가 가능합니다.
pragma solidity ^0.8.0;
// Solidity 컴파일러 버전을 지정합니다. ^0.8.0은 0.8.0 이상의 모든 버전과 호환됩니다.

contract MultiBet {
    // MultiBetExp라는 이름의 스마트 컨트랙트 정의

    address public owner;
    // 계약을 배포한 소유자의 주소를 저장합니다. 소유자는 특정 작업을 수행할 권한을 가집니다.

    constructor() {
        // 컨트랙트의 생성자. 컨트랙트를 배포할 때 한 번만 호출됩니다.
        owner = msg.sender;
        // 배포한 사람의 주소를 소유자로 설정합니다. msg.sender는 현재 함수를 호출한 사람의 주소를 나타냅니다.
    }

    struct Option {
        // Option 구조체 정의: 베팅 옵션을 설명하는 구조입니다.
        string name;
        // 옵션의 이름을 저장하는 문자열
        uint256 totalAmount;
        // 해당 옵션에 걸린 총 베팅 금액을 저장하는 정수
    }

    struct Bet {
        // Bet 구조체 정의: 각 베팅에 대한 정보를 저장하는 구조체
        string topic;
        // 베팅의 주제를 설명하는 문자열
        bool isResolved;
        // 베팅이 해결되었는지를 나타내는 불리언 값. true이면 해결된 상태입니다.
        uint256 totalAmount;
        // 베팅에 걸린 총 금액을 저장하는 정수
        uint256 winningOptionIndex;
        // 승리한 옵션의 인덱스를 저장하는 정수. 베팅이 해결된 후 설정됩니다.
        Option[] options;
        // 베팅의 옵션들을 저장하는 배열
        mapping(address => mapping(uint256 => uint256)) userOptionBetAmount;
        // 각 사용자가 특정 옵션에 베팅한 금액을 저장하는 중첩된 매핑
        mapping(address => bool) isBettor;
        // 사용자가 베팅에 참여했는지 여부를 추적하는 매핑. 베팅한 사용자는 true로 설정됩니다.
        address[] bettors;
        // 베팅에 참여한 모든 사용자의 주소를 저장하는 배열
    }

    mapping(uint256 => Bet) private bets;
    // 베팅 ID를 Bet 구조체에 매핑하는 자료구조. 모든 베팅을 관리합니다.
    uint256 public betCount;
    // 총 베팅 수를 저장하는 정수. 베팅을 생성할 때마다 증가합니다.

    event BetCreated(uint256 indexed betId, string topic, string[] options);
    // BetCreated 이벤트: 새로운 베팅이 생성될 때 발생합니다.
    event BetPlaced(uint256 indexed betId, address indexed user, uint256 amount, string option);
    // BetPlaced 이벤트: 사용자가 베팅을 할 때 발생합니다.
    event BetResolved(uint256 indexed betId, string winningOption);
    // BetResolved 이벤트: 베팅이 해결될 때 발생합니다.

    modifier onlyOwner() {
        // onlyOwner 수정자: 특정 함수가 소유자만 호출할 수 있도록 제한합니다.
        require(msg.sender == owner, "Only the owner can perform this action");
        // msg.sender가 소유자인지 확인합니다. 그렇지 않으면 함수를 실행하지 않고 오류 메시지를 반환합니다.
        _;
        // 수정자 사용 시 함수의 나머지 코드를 실행합니다.
    }

    modifier betExists(uint256 betId) {
        // betExists 수정자: 특정 베팅 ID가 존재하는지 확인합니다.
        require(betId < betCount, "Bet does not exist");
        // betId가 betCount보다 작은지 확인합니다. 그렇지 않으면 함수를 실행하지 않고 오류 메시지를 반환합니다.
        _;
        // 수정자 사용 시 함수의 나머지 코드를 실행합니다.
    }

    function createBet(string memory _topic, string[] memory _options) public onlyOwner {
        // 새로운 베팅을 생성하는 함수. 소유자만 호출할 수 있습니다.
        require(_options.length >= 2, "At least two options are required");
        // 최소 두 개의 옵션이 제공되었는지 확인합니다. 그렇지 않으면 함수를 실행하지 않고 오류를 반환합니다.

        Bet storage newBet = bets[betCount];
        // 새로운 Bet 구조체를 bets 매핑에 저장할 참조를 생성합니다. betCount를 키로 사용합니다.
        newBet.topic = _topic;
        // 베팅의 주제를 설정합니다.

        for (uint256 i = 0; i < _options.length; i++) {
            // 제공된 옵션 배열을 반복하며 각 옵션을 추가합니다.
            newBet.options.push(Option({name: _options[i], totalAmount: 0}));
            // 새로운 Option 구조체를 생성하여 이름과 초기 베팅 금액을 설정한 후 options 배열에 추가합니다.
        }

        emit BetCreated(betCount, _topic, _options);
        // BetCreated 이벤트를 발생시켜 새로운 베팅이 생성되었음을 알립니다.
        betCount++;
        // 총 베팅 수를 증가시킵니다.
    }

    function _findOptionIndex(Bet storage bet, string memory _option) internal view returns (uint256) {
        // 주어진 옵션 이름에 해당하는 인덱스를 찾는 내부 함수. 옵션이 존재하지 않으면 오류를 반환합니다.
        for (uint256 i = 0; i < bet.options.length; i++) {
            // bet의 옵션 배열을 반복하며 일치하는 옵션을 찾습니다.
            if (
                keccak256(abi.encodePacked(bet.options[i].name)) ==
                keccak256(abi.encodePacked(_option))
                // keccak256 해시를 사용해 옵션 이름을 비교합니다. 문자열 비교는 직접 할 수 없으므로 해시를 사용합니다.
            ) {
                return i;
                // 옵션의 인덱스를 반환합니다.
            }
        }
        revert("Option does not exist");
        // 옵션이 존재하지 않으면 오류를 반환합니다.
    }

    function placeBet(uint256 betId, string memory _option) public payable betExists(betId) {
        // 베팅을 하는 함수. 베팅 ID와 옵션 이름을 인자로 받습니다. 베팅 금액은 msg.value에 포함됩니다.
        Bet storage bet = bets[betId];
        // betId에 해당하는 Bet 구조체를 가져옵니다.
        require(!bet.isResolved, "Bet has been resolved");
        // 베팅이 이미 해결되지 않았는지 확인합니다. 해결된 경우 베팅할 수 없습니다.
        require(msg.value > 0, "Bet amount must be greater than zero");
        // 베팅 금액이 0보다 큰지 확인합니다. 그렇지 않으면 오류를 반환합니다.

        uint256 optionIndex = _findOptionIndex(bet, _option);
        // _findOptionIndex 함수를 호출하여 옵션의 인덱스를 찾습니다.

        bet.options[optionIndex].totalAmount += msg.value;
        // 해당 옵션의 총 베팅 금액을 증가시킵니다.
        bet.totalAmount += msg.value;
        // 베팅의 총 금액도 증가시킵니다.
        bet.userOptionBetAmount[msg.sender][optionIndex] += msg.value;
        // 사용자가 해당 옵션에 베팅한 금액을 업데이트합니다.

        if (!bet.isBettor[msg.sender]) {
            // 사용자가 처음으로 베팅하는 경우
            bet.isBettor[msg.sender] = true;
            // 사용자를 베팅자 목록에 추가합니다.
            bet.bettors.push(msg.sender);
            // 베팅자 배열에 사용자의 주소를 추가합니다.
        }

        emit BetPlaced(betId, msg.sender, msg.value, _option);
        // BetPlaced 이벤트를 발생시켜 베팅이 성공적으로 완료되었음을 알립니다.
    }

    function resolveBet(uint256 betId, string memory _winningOption) public onlyOwner betExists(betId) {
        // 베팅을 해결하는 함수. 소유자만 호출할 수 있습니다.
        Bet storage bet = bets[betId];
        // betId에 해당하는 Bet 구조체를 가져옵니다.
        require(!bet.isResolved, "Bet has already been resolved");
        // 베팅이 이미 해결되지 않았는지 확인합니다.

        uint256 winningOptionIndex = _findOptionIndex(bet, _winningOption);
        // _findOptionIndex 함수를 호출하여 승리한 옵션의 인덱스를 찾습니다.

        bet.isResolved = true;
        // 베팅을 해결된 상태로 설정합니다.
        bet.winningOptionIndex = winningOptionIndex;
        // 승리한 옵션의 인덱스를 설정합니다.

        uint256 totalWinnerBetAmount = bet.options[winningOptionIndex].totalAmount;
        // 승리한 옵션에 걸린 총 베팅 금액을 저장합니다.

        if (totalWinnerBetAmount > 0) {
            // 승리한 옵션에 베팅한 금액이 있는 경우
            for (uint256 i = 0; i < bet.bettors.length; i++) {
                // 베팅자 배열을 반복합니다.
                address user = bet.bettors[i];
                // 각 베팅자의 주소를 가져옵니다.
                uint256 userBet = bet.userOptionBetAmount[user][winningOptionIndex];
                // 사용자가 승리한 옵션에 베팅한 금액을 가져옵니다.
                if (userBet > 0) {
                    // 사용자가 승리한 옵션에 베팅한 금액이 있는 경우
                    uint256 reward = (userBet * bet.totalAmount) / totalWinnerBetAmount;
                    // 사용자의 보상을 계산합니다. 비율에 따라 전체 베팅 금액에서 나누어 줍니다.
                    (bool sent, ) = payable(user).call{value: reward}("");
                    // 사용자에게 보상을 전송합니다. call을 사용하여 전송하고 성공 여부를 확인합니다.
                    require(sent, "Failed to send Ether");
                    // 이더 전송이 실패하면 오류를 반환합니다.
                }
            }
        }

        emit BetResolved(betId, _winningOption);
        // BetResolved 이벤트를 발생시켜 베팅이 해결되었음을 알립니다.
    }

    function getBetOptionInfos(uint256 betId)
        public
        view
        betExists(betId)
        returns (
            string[] memory options,
            uint256[] memory optionBets,
            uint256 totalAmount
        )
    {
        // 베팅의 옵션 정보와 각 옵션에 걸린 금액을 반환하는 함수
        Bet storage bet = bets[betId];
        // betId에 해당하는 Bet 구조체를 가져옵니다.
        uint256 optionCount = bet.options.length;
        // 옵션의 개수를 가져옵니다.

        options = new string[](optionCount);
        // 옵션 이름을 저장할 배열을 생성합니다.
        optionBets = new uint256[](optionCount);
        // 각 옵션에 걸린 금액을 저장할 배열을 생성합니다.

        for (uint256 i = 0; i < optionCount; i++) {
            // 옵션 배열을 반복하며 이름과 금액을 설정합니다.
            options[i] = bet.options[i].name;
            // 옵션 이름을 설정합니다.
            optionBets[i] = bet.options[i].totalAmount;
            // 각 옵션에 걸린 금액을 설정합니다.
        }

        totalAmount = bet.totalAmount;
        // 베팅에 걸린 총 금액을 반환합니다.
    }

    function getBet(uint256 betId)
        public
        view
        betExists(betId)
        returns (
            string memory topic,
            bool isResolved,
            uint256 totalAmount,
            string memory winningOption
        )
    {
        // 베팅의 기본 정보를 반환하는 함수
        Bet storage bet = bets[betId];
        // betId에 해당하는 Bet 구조체를 가져옵니다.
        topic = bet.topic;
        // 베팅의 주제를 반환합니다.
        isResolved = bet.isResolved;
        // 베팅이 해결되었는지 여부를 반환합니다.
        totalAmount = bet.totalAmount;
        // 베팅에 걸린 총 금액을 반환합니다.
        if (isResolved) {
            // 베팅이 해결된 경우
            winningOption = bet.options[bet.winningOptionIndex].name;
            // 승리한 옵션의 이름을 반환합니다.
        } else {
            winningOption = "";
            // 베팅이 해결되지 않았으면 빈 문자열을 반환합니다.
        }
    }

    function getUserBet(uint256 betId, address user)
        public
        view
        betExists(betId)
        returns (
            uint256[] memory optionIndexes,
            uint256[] memory betAmounts
        )
    {
        // 특정 사용자의 베팅 정보를 반환하는 함수
        Bet storage bet = bets[betId];
        // betId에 해당하는 Bet 구조체를 가져옵니다.
        uint256 optionCount = bet.options.length;
        // 옵션의 개수를 가져옵니다.

        uint256 count = 0;
        // 사용자가 베팅한 옵션의 개수를 저장할 변수
        for (uint256 i = 0; i < optionCount; i++) {
            // 옵션 배열을 반복하며 사용자가 베팅한 옵션을 찾습니다.
            if (bet.userOptionBetAmount[user][i] > 0) {
                count++;
                // 사용자가 해당 옵션에 베팅한 금액이 있으면 개수를 증가시킵니다.
            }
        }

        optionIndexes = new uint256[](count);
        // 사용자가 베팅한 옵션의 인덱스를 저장할 배열을 생성합니다.
        betAmounts = new uint256[](count);
        // 사용자가 각 옵션에 베팅한 금액을 저장할 배열을 생성합니다.

        uint256 index = 0;
        // 배열에 값을 채우기 위한 인덱스 변수
        for (uint256 i = 0; i < optionCount; i++) {
            // 옵션 배열을 반복하며 사용자의 베팅 금액을 설정합니다.
            uint256 amount = bet.userOptionBetAmount[user][i];
            // 사용자가 해당 옵션에 베팅한 금액을 가져옵니다.
            if (amount > 0) {
                // 베팅 금액이 있는 경우
                optionIndexes[index] = i;
                // 옵션의 인덱스를 설정합니다.
                betAmounts[index] = amount;
                // 베팅 금액을 설정합니다.
                index++;
                // 인덱스를 증가시킵니다.
            }
        }
    }
}
