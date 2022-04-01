// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Base64} from "./utils/Base64.sol";
import {Clerk} from "./Clerk.sol";
import {IEvolve} from "./interfaces/IEvolve.sol";

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";


/// @title Alloy
/// @notice Composable ERC721 Token with Cross-Domain Fungibility
/// @dev Modularized ERC721 tokens that have fungible traits
/// @author andreas@nascent.xyz
contract Alloy is ERC721 {

  /// :::::::::::::::::::::::  ERRORS  :::::::::::::::::::::::: ///

  /// @notice Address has already called `cast`.
  error DuplicateCast();

  /// @notice There are no more coins left.
  error NoMoreCoins();

  /// @notice The msg.sender is not an alloy keep.
  error NotKeep();

  /// :::::::::::::::::::::::::  IMUT  ::::::::::::::::::::::::: ///

  /// @notice The maximum number of coins.
  uint256 immutable public MAXIMUM_TOKENS;

  /// @notice The Clerk Contract
  Clerk immutable public CLERK;

  /// @notice The Evolve Reward Token
  IEvolve constant public EVOLVE = IEvolve(0x14813e8905a0f782F796A5273d2EFbe6551100D6);

  /// @notice The amount of Evolve to mint for keeps.
  uint256 immutable public KEEP_REWARD;

  /// :::::::::::::::::::::::  STORAGE  ::::::::::::::::::::::: ///

  /// @notice The next token id to cast.
  uint256 public nextId;

  /// @notice Maps address to if they've casted.
  mapping(address => bool) public casted;

  /// :::::::::::::::::::::  CONSTRUCTOR  ::::::::::::::::::::: ///

  constructor() ERC721("Alloy", "ALOY") {
    MAXIMUM_TOKENS = 100;
    KEEP_REWARD = 100;
    CLERK = new Clerk();
  }

  /// :::::::::::::::::::::::::  CAST  ::::::::::::::::::::::::: ///

  function cast(address _to) public uniqueAddress moreCoin {
    casted[msg.sender] = true;
    nextId++;
    _mint(_to, nextId);
    EVOLVE.mint(msg.sender, KEEP_REWARD);
  }

  /// :::::::::::::::::::::::::  MELD  ::::::::::::::::::::::::: ///

  /// @notice Allows alloy keeps (token holders) to register new fungible traits (kinks).
  function meld(address kink) external onlyKeep {
    CLERK.meld(kink);
  }

  /// @notice Checks if a kink has been melded.
  function melded(address kink) external view returns (bool) {
    return CLERK.melded(kink);
  }

  /// ::::::::::::::::::::::::::  REAP  ::::::::::::::::::::::: ///

  /// @notice Reaps Kinks
  function reap() external onlyKeep {
    CLERK.reap(msg.sender);
  }

  /// :::::::::::::::::::::::  MODIFIERS  ::::::::::::::::::::: ///

  modifier uniqueAddress() {
    if (casted[msg.sender]) revert DuplicateCast();
    _;
  }

  modifier moreCoin() {
    if (nextId >= MAXIMUM_TOKENS) revert NoMoreCoins();
    _;
  }

  modifier onlyKeep() {
    if (balanceOf[msg.sender] == 0) revert NotKeep();
    _;
  }

  /// :::::::::::::::::::::::  METADATA  :::::::::::::::::::::: ///

  function tokenURI(uint256 id) public view override virtual returns (string memory) {
    string memory baseSvg =
      "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>"
      "<style>.text--line{font-size:400px;font-weight:bold;font-family:'Arial';}"
      ".top-text{fill:#bafe49;font-weight: bold;font-color:#bafe49;font-size:40px;font-family:'Arial';}"
      ".text-copy{fill:none;stroke:white;stroke-dasharray:25% 40%;stroke-width:4px;animation:stroke-offset 9s infinite linear;}"
      ".text-copy:nth-child(1){stroke:#bafe49;stroke-dashoffset:6% * 1;}.text-copy:nth-child(2){stroke:#bafe49;stroke-dashoffset:6% * 2;}"
      ".text-copy:nth-child(3){stroke:#bafe49;stroke-dashoffset:6% * 3;}.text-copy:nth-child(4){stroke:#bafe49;stroke-dashoffset:6% * 4;}"
      ".text-copy:nth-child(5){stroke:#bafe49;stroke-dashoffset:6% * 5;}.text-copy:nth-child(6){stroke:#bafe49;stroke-dashoffset:6% * 6;}"
      ".text-copy:nth-child(7){stroke:#bafe49;stroke-dashoffset:6% * 7;}.text-copy:nth-child(8){stroke:#bafe49;stroke-dashoffset:6% * 8;}"
      ".text-copy:nth-child(9){stroke:#bafe49;stroke-dashoffset:6% * 9;}.text-copy:nth-child(10){stroke:#bafe49;stroke-dashoffset:6% * 10;}"
      "@keyframes stroke-offset{45%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}60%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}}"
      "</style>"
      "<rect width='100%' height='100%' fill='black' />"
      "<symbol id='s-text'>"
      "<text text-anchor='middle' x='50%' y='70%' class='text--line'>Y</text>"
      "</symbol><g class='g-ants'>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use></g>";

    // Convert token id to string
    string memory sTokenId = toString(id);

    // Create the SVG Image
    string memory finalSvg = string(
      abi.encodePacked(
        baseSvg,
        "<text class='top-text' margin='2px' x='4%' y='8%'>",
        sTokenId,
        "</text></svg>"
      )
    );

    // Base64 Encode our JSON Metadata
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Pioneer ',
            sTokenId,
            '", "description": "',
            'Number ',
            sTokenId,
            ' of the Pioneer collection for early Yobot Adopters", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '"}'
          )
        )
      )
    );

    // Prepend data:application/json;base64 to define the base64 encoded data
    return string(
      abi.encodePacked("data:application/json;base64,", json)
    );
  }

  /// :::::::::::::::::::::::  HELPERS  ::::::::::::::::::::::: ///

  /// @notice Converts a uint256 into a string
  /// @param value The value to convert to a string
  function toString(uint256 value) public pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}