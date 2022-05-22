var TokensLocker = artifacts.require("TokensLocker");
var wPresale = artifacts.require("wPresale");

module.exports = function(deployer) {
  deployer.deploy(TokensLocker);
  deployer.deploy(wPresale);
};
