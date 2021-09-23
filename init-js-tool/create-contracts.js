const fs = require('fs')
const replace = require('replace-in-file');
if(process.argv.length !== 5){
        console.log("Enter the desired (1)token, (2)collateral, and then (3)expiry")
        process.exit(0)
    }
    
function generateYieldTokenContract(collateral, expiry){
    let src = "../clarity/contracts/yield-token/yield-wbtc-59760.clar"
    let dest = `./generated-contracts/yield-${collateral}-${expiry}.clar`
    fs.copyFile(src, dest, err =>{
        if (err) {
            console.log("Error found:: ", err)
        }
    })
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [collateral, expiry]
    })
}

function generatePoolTokenContract(collateral, expiry){
    let src = "../clarity/contracts/pool-token/ytp-yield-wbtc-59760-wbtc.clar"
    let dest = `./generated-contracts/ytp-yield-${collateral}-${expiry}-${collateral}.clar`
    fs.copyFile(src, dest, err =>{
        if (err) {
            console.log("Error found:: ", err)
        }
    })
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [collateral, expiry]
    })
}

function generateKeyTokenContract(token, collateral, expiry){
    let src = "../clarity/contracts/key-token/key-wbtc-59760-usda.clar"
    let dest = `./generated-contracts/key-${collateral}-${expiry}-${token}.clar`
    fs.copyFile(src, dest, err =>{
        if (err) {
            console.log("Error found:: ", err)
        }
    })
    replace.sync({
        files: dest,
        from: [/usda/g, /wbtc/g, /59760/g],
        to: [token, collateral, expiry]
    })
}

function generateMultisigCRP(token, collateral, expiry){
    let src = "../clarity/contracts/multisig/multisig-crp-wbtc-59760-usda.clar"
    let dest = `./generated-contracts/multisig-crp-${collateral}-${expiry}-${token}.clar`
    fs.copyFile(src, dest, err =>{
        if (err) {
            console.log("Error found:: ", err)
        }
    })
    replace.sync({
        files: dest,
        from: [/usda/g, /wbtc/g, /59760/g],
        to: [token, collateral, expiry]
    })
}

function generateMultisigYTPYield(collateral, expiry){
    let src = "../clarity/contracts/multisig/multisig-ytp-yield-wbtc-59760-wbtc.clar"
    let dest = `./generated-contracts/multisig-ytp-yield-${collateral}-${expiry}-${collateral}.clar`
    fs.copyFile(src, dest, err =>{
        if (err) {
            console.log("Error found:: ", err)
        }
    })
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [collateral, expiry]
    })
}


async function run() {
    let token = process.argv[2]
    let collateral = process.argv[3]
    let expiry = process.argv[4]
    generateKeyTokenContract(token, collateral, expiry)
    generateYieldTokenContract(collateral, expiry)
    generatePoolTokenContract(collateral, expiry)
    generateMultisigCRP(token, collateral, expiry)
    generateMultisigYTPYield(collateral, expiry)

}
run()