const fs = require('fs')
const replace = require('replace-in-file');
const toml = require('toml');

const clarinet_config = toml.parse(fs.readFileSync('../clarity/Clarinet.toml', 'utf-8'))

if(process.argv.length !== 5){
        console.log("Enter the desired (1)collateral, (2)token, and then (3)expiry")
        process.exit(0)
    }
let contracts = []    
function generateYieldTokenContract(token, expiry){
    let base_path = "../clarity/contracts/yield-token/"
    let src = base_path + "yield-wbtc-59760.clar"
    let new_name = `yield-${token}-${expiry}`
    let dest = base_path + new_name + '.clar'
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [token, expiry]
    })
    contracts.push(new_name)
    let old_path_split = clarinet_config.contracts['yield-wbtc-59760'].path.split('/')
    let new_path = old_path_split.slice(0,2).join('/') + '/' + new_name + '.clar'
    let deps = clarinet_config.contracts['yield-wbtc-59760'].depends_on
    
    let stringified_deps = deps.map(dep => "\"" + dep + "\"" )
    const new_config = `\n[contracts.${new_name}]\npath = "${new_path}"\ndepends_on = [${stringified_deps}]\n`
    fs.appendFileSync('../clarity/Clarinet.toml', new_config);
}

function generatePoolTokenContract(token, expiry){
    let base_path = "../clarity/contracts/pool-token/"
    let src = base_path + "ytp-yield-wbtc-59760-wbtc.clar"
    let new_name = `ytp-yield-${token}-${expiry}-${token}.clar`
    let dest = base_path + new_name + '.clar'
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [token, expiry]
    })
    contracts.push(`ytp-yield-${token}-${expiry}-${token}.clar`)
    let old_path_split = clarinet_config.contracts['ytp-yield-wbtc-59760-wbtc'].path.split('/')
    let new_path = old_path_split.slice(0,2).join('/') + '/' + new_name + '.clar'
    let deps = clarinet_config.contracts['ytp-yield-wbtc-59760-wbtc'].depends_on
    
    let stringified_deps = deps.map(dep => "\"" + dep + "\"" )
    const new_config = `\n[contracts.${new_name}]\npath = "${new_path}"\ndepends_on = [${stringified_deps}]\n`
    fs.appendFileSync('../clarity/Clarinet.toml', new_config);
}

function generateKeyTokenContract(collateral, token, expiry){
    let base_path = "../clarity/contracts/key-token/"
    let src = base_path + "key-wbtc-59760-usda.clar"
    let new_name = `key-${token}-${expiry}-${collateral}.clar`
    let dest = base_path + new_name + '.clar'
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    if (collateral === 'wbtc'){
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: ['collateralfoo', 'tokenfoo', expiry]
        })
        replace.sync({
            files: dest,
            from: [/collateralfoo/g, /tokenfoo/g],
            to: [collateral, token]
        })
    }
    else{
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: [collateral, token, expiry]
        })
    }
    contracts.push(`key-${token}-${expiry}-${collateral}.clar`)
    let old_path_split = clarinet_config.contracts['key-wbtc-59760-usda'].path.split('/')
    let new_path = old_path_split.slice(0,2).join('/') + '/' + new_name + '.clar'
    let deps = clarinet_config.contracts['key-wbtc-59760-usda'].depends_on
    let stringified_deps = deps.map(dep => "\"" + dep + "\"" )
    const new_config = `\n[contracts.${new_name}]\npath = "${new_path}"\ndepends_on = [${stringified_deps}]\n`
    fs.appendFileSync('../clarity/Clarinet.toml', new_config);
}

function generateMultisigCRP(collateral, token, expiry){
    let base_path = "../clarity/contracts/multisig/"
    let src = base_path + "multisig-crp-wbtc-59760-usda.clar"
    let dest = base_path + `multisig-crp-${token}-${expiry}-${collateral}.clar`
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    if (collateral === 'wbtc'){
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: ['collateralfoo', 'tokenfoo', expiry]
        })
        replace.sync({
            files: dest,
            from: [/collateralfoo/g, /tokenfoo/g],
            to: [collateral, token]
        })
    }
    else{
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: [collateral, token, expiry]
        })
    }
    contracts.push(`multisig-crp-${token}-${expiry}-${collateral}.clar`)

}

function generateMultisigYTPYield(token, expiry){
    let base_path = "../clarity/contracts/multisig/"
    let src = base_path + "multisig-ytp-yield-wbtc-59760-wbtc.clar"
    let dest = base_path + `multisig-ytp-yield-${token}-${expiry}-${token}.clar`
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    replace.sync({
        files: dest,
        from: [/wbtc/g, /59760/g],
        to: [token, expiry]
    })
    contracts.push(`multisig-ytp-yield-${token}-${expiry}-${token}.clar`)
}

function generateFlashLoanUser(collateral, token, expiry) {
    let base_path = "../clarity/contracts/"
    let src = base_path + "flash-loan-user-margin-usda-wbtc-59760.clar"
    let dest = base_path + `flash-loan-user-margin-${collateral}-${token}-${expiry}.clar`
    fs.copyFileSync(src, dest, fs.constants.COPYFILE_EXCL)
    
    if (collateral === 'wbtc'){
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: ['collateralfoo', 'tokenfoo', expiry]
        })
        replace.sync({
            files: dest,
            from: [/collateralfoo/g, /tokenfoo/g],
            to: [collateral, token]
        })
    }
    else{
        replace.sync({
            files: dest,
            from: [/usda/g, /wbtc/g, /59760/g],
            to: [collateral, token, expiry]
        })
    }
    contracts.push(`flash-loan-user-margin-${collateral}-${token}-${expiry}.clar`)
}


function run() {
    let collateral = process.argv[2]
    let token = process.argv[3]
    let expiry = process.argv[4]
    generateYieldTokenContract(token, expiry)
    generatePoolTokenContract(token, expiry)
    generateKeyTokenContract(collateral, token, expiry)
    // generateMultisigCRP(collateral, token, expiry)
    // generateMultisigYTPYield(token, expiry)
    // generateFlashLoanUser(collateral, token, expiry)
    // console.log(contracts);
}
run()