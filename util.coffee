url = require 'url'
{ Client } = require('bitcoin')

SATOSHI = 100000000

iferr = (fail, succ) -> (err, a...) -> if err? then fail err else succ a...

bitcoin_jsonrpc = (uri) ->
  { hostname: host, port, auth, protocol } = url.parse uri
  [ user, pass ] = auth.split(':') if auth?
  new Client { host, port, user, pass, ssl: (protocol is 'bitcoins:') }

out_paid_to = (vout, address) ->
  vout.scriptPubKey.addresses.length is 1 and vout.scriptPubKey.addresses[0] is address

format_unspent = ({ tx, vout }) ->
  txid: tx.txid
  n: vout.n
  value: vout.value * SATOSHI
  value_bitcoin: vout.value
  script: vout.scriptPubKey.hex
  confirmations: tx.confirmations

module.exports = { iferr, bitcoin_jsonrpc, out_paid_to, format_unspent }
