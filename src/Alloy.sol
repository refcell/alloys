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
    MAXIMUM_TOKENS = 1_000;
    KEEP_REWARD = 10_000;
    CLERK = new Clerk();
  }

  /// :::::::::::::::::::::::::  CAST  ::::::::::::::::::::::::: ///

  /// @notice Mints a new Alloy ERC721
  /// @param _to The address to mint the Alloy ERC721 token to
  function cast(address _to) public uniqueAddress moreCoin {
    casted[msg.sender] = true;
    uint256 nId = nextId + 1; // sload
    _mint(_to, nId);
    nextId = nId; // sstore
    EVOLVE.mint(msg.sender, KEEP_REWARD);
  }

  /// :::::::::::::::::::::::::  BREN  ::::::::::::::::::::::::: ///

  /// @notice Stakes the token in a given kink
  function bren(uint256 id, address kink) public onlyKeeper(id) {
    CLERK.bren(id, kink);
  }

  /// :::::::::::::::::::::::::  PLOY  ::::::::::::::::::::::::: ///

  /// @notice Returns all melded kinks via the Clerk
  function ploy() external view returns (address[] memory) {
    return CLERK.mass();
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

  /// ::::::::::::::::::::::::::  SUIT  ::::::::::::::::::::::: ///

  /// @notice Equips a kink onto a keep's alloy.
  function suit(address kink, uint256 id, bool suited) external onlyKeeper(id) {
    CLERK.suit(kink, id, suited);
  }

  /// @notice Returns if a kink is suited
  function suited(address kink, uint256 id) external view returns(bool) {
    return CLERK.suited(id, CLERK.kinkcs(kink));
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

  modifier onlyKeeper(uint256 id) {
    if (msg.sender != ownerOf[id]) revert NotKeep();
    _;
  }

  /// :::::::::::::::::::::::  METADATA  :::::::::::::::::::::: ///

  function tokenURI(uint256 id) public view override virtual returns (string memory) {

    // Fetch the equiped kinks for a given token id
    (string memory styles, string memory html) = CLERK.pile(id);

    // Convert token id to string
    string memory sTokenId = toString(id);

    // Create the SVG Image
    string memory rendered = string(
      abi.encodePacked(
        "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><style>",
        styles,
        html,
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
            '{"name": "', name, ' ',
            sTokenId,
            '", "description": "',
            name, ' Number ',
            sTokenId,
            ' of the ', name, ' collection for shadowy production testers.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(rendered)),
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