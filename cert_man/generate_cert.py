#!/usr/bin/python
import os
import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description='SSL generator')

    parser.add_argument('--base_dn', dest='base_dn', action='store',
                    type=str,
                    #required=True,
                    default='local',
                    help='Base DNS string. ssl_name.BASEDN')

    parser.add_argument('--ssl_name', dest='ssl_name', action='store',
                    type=str,
                    required=True,
                    help='SSL Name string. SSL_NAME.basedn')

    try:
        args = parser.parse_args()
        if len(sys.argv) == 1:
            raise Exception
    except Exception as e:
        print(e)
        parser.print_help(sys.stderr)
        exit()
    return args


if __name__ == '__main__':
   args = get_args()
   base_dn = args.base_dn
   ssl_name = args.ssl_name
   new_path = f'{ssl_name}.{base_dn}'
   os.mkdir(new_path)

   print('\n\n[*] Step 1. New key')
   base_cmd_1 = f'openssl genrsa -out {new_path}/{ssl_name}.{base_dn}.key 2048'
   print(base_cmd_1)
   os.system(base_cmd_1)

   print('\n\n[*] Step 2. New CSR')
   base_cmd_2 = f'openssl req -new --nodes -key {new_path}/{ssl_name}.{base_dn}.key -out {new_path}/{ssl_name}.{base_dn}.csr'
   print(base_cmd_2)
   os.system(base_cmd_2)


   base_file = '''authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]'''

   base_file_2 = f'DNS.1 = {ssl_name}.{base_dn}'
   print('\n\n[*] Step 3. New ext file')
   with open(f'{new_path}/{ssl_name}.{base_dn}.ext', 'w') as f_obj:
      f_obj.write(base_file)
      f_obj.write('\n')
      f_obj.write(base_file_2)


   print('\n\n[*] Step 4. New certs')
   base_cmd_3 = f'openssl x509 -req -in {new_path}/{ssl_name}.{base_dn}.csr -CA ./home_ca/ca.crt -CAkey ./home_ca/ca.key -CAcreateserial -out {new_path}/{ssl_name}.{base_dn}.crt -days 3650 -sha256 -extfile {new_path}/{ssl_name}.{base_dn}.ext'
   print(base_cmd_3)
   os.system(base_cmd_3)
